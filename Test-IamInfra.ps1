<#
.SYNOPSIS
    Smoke-тесты IAM инфраструктуры — Phase 0

.КАК ЗАПУСКАТЬ
    Из корня репозитория (PMServices):

    .\Test-IamInfra.ps1
    .\Test-IamInfra.ps1 -Group Edge
    .\Test-IamInfra.ps1 -Group Keycloak
    .\Test-IamInfra.ps1 -Group Database
    .\Test-IamInfra.ps1 -Group Redis
    .\Test-IamInfra.ps1 -Group Mailpit
    .\Test-IamInfra.ps1 -Group RateLimit
#>
param(
    [ValidateSet("All","Compose","Containers","Edge","Keycloak","Database","Redis","Mailpit","RateLimit")]
    [string]$Group = "All"
)

$EnvFile = "ops\iam\.env.iam"
# Определяем реальный префикс из docker ps
# Docker берёт имя проекта из папки где лежат compose-файлы (ops/iam → "iam"),
# а не из корня репозитория
$detected = & docker ps --format "{{.Names}}" 2>$null |
    Select-String -Pattern '^(\w+)-(keycloak|postgres-iam|redis|mailpit|edge|postgres-kc)-1$' |
    ForEach-Object { $_.Matches[0].Groups[1].Value } |
    Select-Object -First 1
$Project = if ($detected) { $detected } else { "iam" }

# ── Читаем .env.iam ───────────────────────────────────────────
function Read-Env([string]$Path) {
    $v = @{}
    if (-not (Test-Path $Path)) { return $v }
    Get-Content $Path | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            $v[$Matches[1].Trim()] = $Matches[2].Trim() -replace '\s*#.*$', ''
        }
    }
    return $v
}
$E = Read-Env $EnvFile

# Читаем параметры из .env — единый источник правды для тестов
$EdgePort      = if ($E["EDGE_HTTP_PORT"]) { $E["EDGE_HTTP_PORT"] } else { "8090" }
$EdgeUrl       = "http://localhost:$EdgePort"
$KeycloakRealm = if ($E["KEYCLOAK_REALM"])  { $E["KEYCLOAK_REALM"] }  else { "pmplatform" }

# ── HTTP запрос, не бросает исключение на 4xx/5xx ────────────
function Invoke-Http([string]$Path) {
    try {
        return Invoke-WebRequest -Uri "$EdgeUrl$Path" -TimeoutSec 10 -ErrorAction Stop
    } catch [System.Net.WebException] {
        # PowerShell < 7.4 бросает исключение на 4xx/5xx — достаём ответ из него
        $resp = $_.Exception.Response
        if ($resp) {
            return [PSCustomObject]@{
                StatusCode = [int]$resp.StatusCode
                Content    = ""
                Headers    = @{}
            }
        }
        throw
    } catch {
        # Invoke-WebRequest в PS 7.x оборачивает HTTP-ошибки иначе
        if ($_.Exception.Response) {
            $resp = $_.Exception.Response
            return [PSCustomObject]@{
                StatusCode = [int]$resp.StatusCode
                Content    = ""
                Headers    = @{}
            }
        }
        throw
    }
}

# ── docker exec (переименовано чтобы не конфликтовало с командой docker) ──
function Invoke-DockerExec([string]$Container, [string[]]$Cmd) {
    & docker exec "$Project-$Container" @Cmd 2>&1
}

function Invoke-DockerInspect([string]$Container) {
    & docker inspect "$Project-$Container" 2>$null | ConvertFrom-Json
}

# ── Фреймворк ─────────────────────────────────────────────────
$Pass = 0; $Fail = 0; $Errors = @()

function Test-Case([string]$Name, [scriptblock]$Body) {
    Write-Host "  ⏳ $Name" -NoNewline
    try {
        $r = & $Body
        if ($r -eq $false) { throw "вернул false" }
        $script:Pass++
        Write-Host "`r  ✅ $Name" -ForegroundColor Green
    } catch {
        $script:Fail++
        $script:Errors += "[$Name] $_"
        Write-Host "`r  ❌ $Name" -ForegroundColor Red
        Write-Host "     → $_"   -ForegroundColor DarkRed
    }
}

function Section([string]$Name) {
    Write-Host ""
    Write-Host "━━━ $Name " -ForegroundColor Cyan -NoNewline
    Write-Host ("━" * [Math]::Max(1, 54 - $Name.Length)) -ForegroundColor Cyan
}

# ══════════════════════════════════════════════════════════════
#  Compose — инварианты файлов конфигурации
# ══════════════════════════════════════════════════════════════
function Test-Compose {
    Section "Compose — инварианты конфигурации"

    Test-Case "Base compose не содержит nginx bind-mount'ов (prod-like)" {
        # Инвариант: nginx конфиг должен браться из образа (COPY в Dockerfile), не с хоста.
        # Намеренные bind-mount'ы в base compose:
        #   - ./initdb (postgres-iam) — скрипты инициализации БД, только при первом старте
        #   - ./keycloak/realm-export.json (keycloak) — конфиг realm при импорте
        # Запрещённые bind-mount'ы в base compose (должны быть только в dev overlay):
        #   - ./nginx/default.conf — nginx конфиг (в проде берётся из образа)
        #   - ./nginx/snippets/* — security headers snippet
        # Тест ловит регресс "кто-то вернул nginx bind-mount в базовый compose".

        $baseContent = Get-Content "ops\iam\compose.iam.yml" -Raw
        if ($baseContent -match "\./nginx/default\.conf") {
            throw "base compose содержит bind-mount ./nginx/default.conf — должен быть только в dev overlay"
        }
        if ($baseContent -match "\./nginx/snippets") {
            throw "base compose содержит bind-mount ./nginx/snippets — должен быть только в dev overlay"
        }
    }

    Test-Case "Dev overlay добавляет nginx bind-mount'ы для edge" {
        # Инвариант: dev overlay ДОЛЖЕН монтировать default.conf и security_headers.conf.
        # Если кто-то их уберет из dev overlay — это значит "конфиг нельзя менять без rebuild".
        $devCompose = "ops\iam\compose.iam.dev.yml"
        if (-not (Test-Path $devCompose)) { throw "не найден $devCompose" }
        $devContent = Get-Content $devCompose -Raw
        if ($devContent -notmatch "default\.conf")          { throw "dev overlay не монтирует default.conf" }
        if ($devContent -notmatch "security_headers\.conf") { throw "dev overlay не монтирует security_headers.conf" }
    }
}

# ══════════════════════════════════════════════════════════════
#  Containers
# ══════════════════════════════════════════════════════════════
function Test-Containers {
    Section "Containers — сервисы запущены"

    foreach ($c in @("edge","keycloak","postgres-iam","postgres-kc","redis","mailpit")) {
        Test-Case "Контейнер $c — running" {
            $info = Invoke-DockerInspect "$c-1"
            if (-not $info) { throw "не найден (ожидалось '$Project-$c-1')" }
            if ($info[0].State.Status -ne "running") { throw "статус: $($info[0].State.Status)" }
        }
    }

    foreach ($c in @("keycloak","postgres-iam","postgres-kc","redis")) {
        Test-Case "Контейнер $c — healthy" {
            $info = Invoke-DockerInspect "$c-1"
            $h = $info[0].State.Health.Status
            if ($h -ne "healthy") { throw "health: $h" }
        }
    }

    Test-Case "Keycloak НЕ публикует порты наружу" {
        $info  = Invoke-DockerInspect "keycloak-1"
        $ports = $info[0].NetworkSettings.Ports.PSObject.Properties |
                 Where-Object { $_.Value -ne $null }
        if ($ports) { throw "KC открыл порты: $($ports.Name -join ', ')" }
    }
    Test-Case "Сетевая изоляция — контейнеры только в ожидаемых сетях" {
        # Инвариант: edge не должен быть в db, postgres не должен быть в frontend.
        # Любая правка compose, нарушающая это — сразу поймается тестом.
        $expected = @{
            "edge-1"         = @("${Project}_frontend", "${Project}_backend")
            "keycloak-1"     = @("${Project}_backend",  "${Project}_db")
            "postgres-kc-1"  = @("${Project}_db")
            "postgres-iam-1" = @("${Project}_db")
            "redis-1"        = @("${Project}_backend")
            "mailpit-1"      = @("${Project}_backend")
        }
        foreach ($c in $expected.Keys) {
            $j    = Invoke-DockerInspect $c
            if (-not $j) { throw "контейнер $c не найден" }
            $nets = @($j[0].NetworkSettings.Networks.PSObject.Properties.Name)
            $want = @($expected[$c])
            $extra   = @($nets | Where-Object { $_ -notin $want })
            $missing = @($want | Where-Object { $_ -notin $nets })
            if ($extra.Count -gt 0 -or $missing.Count -gt 0) {
                throw ("${c}: лишние=[{0}] недостающие=[{1}]" -f ($extra -join ','), ($missing -join ','))
            }
        }
    }
}

# ══════════════════════════════════════════════════════════════
#  Edge
# ══════════════════════════════════════════════════════════════
function Test-Edge {
    Section "Edge — nginx"

    Test-Case "GET / → 200 'edge ok'" {
        $r = Invoke-Http "/"
        if ($r.StatusCode -ne 200) { throw "статус: $($r.StatusCode)" }
        $body = if ($r.Content -is [byte[]]) {
            [System.Text.Encoding]::UTF8.GetString($r.Content)
        } else { [string]$r.Content }
        if ($body -notmatch "edge ok") { throw "тело: '$body'" }
    }

    Test-Case "GET /__edge/healthz → 200" {
        $r = Invoke-Http "/__edge/healthz"
        if ($r.StatusCode -ne 200) { throw "статус: $($r.StatusCode)" }
    }

    Test-Case "X-Frame-Options: DENY" {
        $r = Invoke-Http "/__edge/healthz"
        $h = $r.Headers["X-Frame-Options"]
        if (-not $h) { throw "заголовок отсутствует" }
        if ($h -ne "DENY") { throw "значение: '$h'" }
    }

    Test-Case "X-Content-Type-Options: nosniff" {
        $r = Invoke-Http "/__edge/healthz"
        $h = $r.Headers["X-Content-Type-Options"]
        if ($h -ne "nosniff") { throw "значение: '$h'" }
    }

    Test-Case "Content-Security-Policy присутствует" {
        $r = Invoke-Http "/__edge/healthz"
        if (-not $r.Headers["Content-Security-Policy"]) { throw "заголовок отсутствует" }
    }

    Test-Case "server_tokens off (версия nginx скрыта)" {
        $r = Invoke-Http "/__edge/healthz"
        $s = $r.Headers["Server"]
        if ($s -match "\d+\.\d+") { throw "версия раскрыта: '$s'" }
    }

    Test-Case "nginx конфиг валиден (nginx -t)" {
        $out = Invoke-DockerExec "edge-1" @("nginx", "-t")
        if ($out -notmatch "syntax is ok|test is successful") { throw $out }
    }
    Test-Case "/resources/* содержит security headers (add_header inheritance)" {
        # Invoke-Http теряет headers на 4xx (возвращает Headers=@{}).
        # Nginx добавляет security headers ко всем ответам ("always") — включая 4xx.
        # Запрашиваем несуществующий путь: nginx отдаст 404 с полными security headers.
        $uri = "$EdgeUrl/resources/__security-header-check__"
        try {
            # -SkipHttpErrorCheck (PS 7.1+): ответ без исключения даже на 4xx
            $r    = Invoke-WebRequest -Uri $uri -TimeoutSec 10 -SkipHttpErrorCheck -ErrorAction Stop
            $hdrs = $r.Headers
            $sc   = [int]$r.StatusCode
        } catch {
            # Fallback для PS < 7.1
            $resp = $_.Exception.Response
            if (-not $resp) { throw }
            $hdrs = @{}
            try   { foreach ($k  in $resp.Headers.AllKeys) { $hdrs[$k]      = $resp.Headers[$k]     } }
            catch { foreach ($kv in $resp.Headers)         { $hdrs[$kv.Key] = ($kv.Value -join ',')  } }
            $sc = [int]$resp.StatusCode
        }
        if ($sc -eq 403) { throw "/resources/ заблокирован nginx — проверь whitelist в default.conf" }
        foreach ($h in @("X-Frame-Options","X-Content-Type-Options","Content-Security-Policy")) {
            if (-not $hdrs[$h]) {
                throw "отсутствует $h на /resources/* — add_header inheritance регресс в nginx"
            }
        }
    }
}

# ══════════════════════════════════════════════════════════════
#  Keycloak
# ══════════════════════════════════════════════════════════════
function Test-Keycloak {
    Section "Keycloak — whitelist и запреты"

    @(
        @{ P="/admin/";                                                               N="Admin Console"       }
        @{ P="/metrics";                                                              N="Metrics"             }
        @{ P="/realms/master/";                                                       N="Master realm"        }
        @{ P="/realms/$KeycloakRealm/protocol/openid-connect/token";                      N="Token endpoint"      }
        @{ P="/realms/$KeycloakRealm/protocol/openid-connect/userinfo";                   N="Userinfo"            }
        @{ P="/realms/$KeycloakRealm/protocol/openid-connect/certs";                      N="JWKS/Certs"          }
        @{ P="/realms/$KeycloakRealm/protocol/openid-connect/token/introspect";           N="Introspect"          }
        @{ P="/realms/$KeycloakRealm/.well-known/openid-configuration";                   N="OIDC Discovery"      }
        @{ P="/realms/otherrealm/protocol/openid-connect/auth";                       N="Чужой realm"         }
        @{ P="/kc/anything";                                                          N="Honeypot /kc/"       }
        @{ P="/wp-admin/";                                                            N="Honeypot /wp-admin/" }
        @{ P="/.env";                                                                 N="Honeypot /.env"      }
    ) | ForEach-Object {
        $item = $_
        Test-Case "BLOCK $($item.N) → 403" {
            $r = Invoke-Http $item.P
            if ($r.StatusCode -ne 403) { throw "статус: $($r.StatusCode)" }
        }
    }

    Test-Case "ALLOW KC Login page → 200 или 302" {
        $redirect = [System.Uri]::EscapeDataString("$EdgeUrl/auth/callback")
        $url = "$EdgeUrl/realms/$KeycloakRealm/protocol/openid-connect/auth" +
               "?client_id=bff&response_type=code" +
               "&redirect_uri=$redirect"
        # MaximumRedirection 0 — не следуем за редиректами KC.
        # KC auth → 302 (начало auth flow) — это успех, проверять тело логин-страницы не нужно.
        # Следование редиректам без KC-сессионной cookie вызывает 502 от nginx.
        try {
            $r = Invoke-WebRequest -Uri $url -TimeoutSec 10 -MaximumRedirection 0 -ErrorAction Stop
            if ($r.StatusCode -notin @(200, 302)) { throw "статус: $($r.StatusCode)" }
        } catch [System.Net.WebException] {
            $resp = $_.Exception.Response
            if ($resp) {
                $code = [int]$resp.StatusCode
                if ($code -notin @(200, 302)) { throw "статус: $code" }
            } else { throw }
        } catch {
            # PS7: 302 при MaximumRedirection=0 бросает исключение с кодом
            if ($_ -match "302|Found|redirect") { return }
            if ($_.Exception.Response) {
                $code = [int]$_.Exception.Response.StatusCode
                if ($code -notin @(200, 302)) { throw "статус: $code" }
            } else { throw }
        }
    }

    Test-Case "KC_HOSTNAME корректен — Location не содержит keycloak:8080" {
        # KC при конфигурации KC_PROXY_HEADERS=xforwarded должен формировать
        # redirect URLs через публичный hostname (Edge), а не внутренний keycloak:8080.
        # Тест ловит регресс KC_HOSTNAME / X-Forwarded-* конфигурации.
        try {
            $r = Invoke-WebRequest -Uri "$EdgeUrl/realms/$KeycloakRealm/account/" `
                 -MaximumRedirection 0 -TimeoutSec 5 -ErrorAction Stop
            $loc = $r.Headers["Location"]
        } catch {
            # PS7 бросает исключение на 302 при MaximumRedirection 0
            $loc = $_.Exception.Response.Headers.Location
        }
        if ($loc -and $loc -match "keycloak:8080") {
            throw "Location содержит внутренний хост: $loc"
        }
        # Если редирект есть — он должен указывать на публичный Edge
        if ($loc -and $loc -notmatch "localhost") {
            Write-Host "    ⚠️  Location: $loc" -ForegroundColor Yellow
        }
    }

    Test-Case "Зоны rate limit объявлены в конфиге" {
        $out = (Invoke-DockerExec "edge-1" @("nginx", "-T") | Out-String)
        if ($out -notmatch "kc_auth")             { throw "зона kc_auth не найдена"      }
        if ($out -notmatch "kc_action")           { throw "зона kc_action не найдена"    }
        if ($out -notmatch "limit_req_status 429"){ throw "limit_req_status 429 не найден" }
    }
}

# ══════════════════════════════════════════════════════════════
#  Database
# ══════════════════════════════════════════════════════════════
function Test-Database {
    Section "Database — PostgreSQL IAM"

    $u = $E["IAM_PG_USER"]; $d = $E["IAM_PG_DB"]

    Test-Case "PostgreSQL IAM — принимает подключения" {
        $r = Invoke-DockerExec "postgres-iam-1" @("pg_isready", "-U", $u, "-d", $d)
        if ($r -notmatch "accepting connections") { throw $r }
    }

    Test-Case "Роль iam_app существует" {
        $r = Invoke-DockerExec "postgres-iam-1" @(
            "psql","-U",$u,"-d",$d,"-tAc",
            "SELECT 1 FROM pg_roles WHERE rolname='iam_app'")
        if (($r | Out-String).Trim() -ne "1") { throw "роль не найдена" }
    }

    Test-Case "Роль iam_migrator существует" {
        $r = Invoke-DockerExec "postgres-iam-1" @(
            "psql","-U",$u,"-d",$d,"-tAc",
            "SELECT 1 FROM pg_roles WHERE rolname='iam_migrator'")
        if (($r | Out-String).Trim() -ne "1") { throw "роль не найдена" }
    }

    Test-Case "iam_migrator — владелец БД iam" {
        $r = Invoke-DockerExec "postgres-iam-1" @(
            "psql","-U",$u,"-d",$d,"-tAc",
            "SELECT pg_get_userbyid(datdba) FROM pg_database WHERE datname='$d'")
        if (($r | Out-String).Trim() -ne "iam_migrator") { throw "владелец: '$(($r | Out-String).Trim())'" }
    }

    Test-Case "PUBLIC лишён CONNECT на БД iam" {
        $r = Invoke-DockerExec "postgres-iam-1" @(
            "psql","-U",$u,"-d",$d,"-tAc",
            "SELECT has_database_privilege('PUBLIC','$d','CONNECT')")
        if (($r | Out-String).Trim() -eq "t") { throw "PUBLIC имеет CONNECT — REVOKE не сработал" }
    }

    Test-Case "iam_app — не суперпользователь" {
        $r = Invoke-DockerExec "postgres-iam-1" @(
            "psql","-U",$u,"-d",$d,"-tAc",
            "SELECT rolsuper FROM pg_roles WHERE rolname='iam_app'")
        if (($r | Out-String).Trim() -ne "f") { throw "iam_app — суперпользователь!" }
    }

    Test-Case "PostgreSQL KC — принимает подключения" {
        $ku = $E["KC_PG_USER"]; $kd = $E["KC_PG_DB"]
        $r  = Invoke-DockerExec "postgres-kc-1" @("pg_isready", "-U", $ku, "-d", $kd)
        if ($r -notmatch "accepting connections") { throw $r }
    }
}

# ══════════════════════════════════════════════════════════════
#  Redis
# ══════════════════════════════════════════════════════════════
function Test-Redis {
    Section "Redis"

    $pw = $E["REDIS_PASSWORD"]

    Test-Case "PING с паролем → PONG" {
        $r = Invoke-DockerExec "redis-1" @("redis-cli", "--no-auth-warning", "-a", $pw, "PING")
        if ($r -notmatch "PONG") { throw "ответ: '$r'" }
    }

    Test-Case "PING без пароля → NOAUTH" {
        $r = Invoke-DockerExec "redis-1" @("redis-cli", "PING")
        if ($r -notmatch "NOAUTH|ERR") { throw "Redis принял без пароля: '$r'" }
    }

    Test-Case "SET/GET работает" {
        Invoke-DockerExec "redis-1" @("redis-cli","-a",$pw,"SET","smoke:test","ok","EX","60") | Out-Null
        $r = Invoke-DockerExec "redis-1" @("redis-cli", "--no-auth-warning", "-a", $pw, "GET", "smoke:test")
        $rs = ($r | Out-String).Trim()
        if ($rs -ne "ok") { throw "GET вернул: '$rs'" }
    }

    Test-Case "maxmemory-policy = noeviction" {
        $r = Invoke-DockerExec "redis-1" @("redis-cli","-a",$pw,"CONFIG","GET","maxmemory-policy")
        if (($r | Out-String) -notmatch "noeviction") { throw "policy: '$($r | Out-String)'" }
    }

    Test-Case "AOF включён" {
        $r = Invoke-DockerExec "redis-1" @("redis-cli","-a",$pw,"CONFIG","GET","appendonly")
        if (($r | Out-String) -notmatch "yes") { throw "appendonly: '$($r | Out-String)'" }
    }
}

# ══════════════════════════════════════════════════════════════
#  Mailpit
# ══════════════════════════════════════════════════════════════
function Test-Mailpit {
    Section "Mailpit — email"

    $wp = $E["MAILPIT_WEB_PORT"]
    $sp = $E["MAILPIT_SMTP_PORT"]

    Test-Case "Web UI → 200" {
        $r = Invoke-WebRequest -Uri "http://localhost:$wp" -TimeoutSec 5 -ErrorAction Stop
        if ($r.StatusCode -ne 200) { throw "статус: $($r.StatusCode)" }
    }

    Test-Case "API /api/v1/messages → 200" {
        $r = Invoke-WebRequest -Uri "http://localhost:$wp/api/v1/messages" -TimeoutSec 5 -ErrorAction Stop
        if ($r.StatusCode -ne 200) { throw "статус: $($r.StatusCode)" }
    }

    Test-Case "SMTP порт $sp слушает" {
        $t = Test-NetConnection -ComputerName localhost -Port $sp -WarningAction SilentlyContinue
        if (-not $t.TcpTestSucceeded) { throw "порт $sp недоступен" }
    }
}

# ══════════════════════════════════════════════════════════════
#  Rate limiting
# ══════════════════════════════════════════════════════════════
function Test-RateLimit {
    Section "Rate limiting — защита от brute force"

    Test-Case "15 быстрых запросов на /auth → 429 появляется" {
        $url = "/realms/$KeycloakRealm/protocol/openid-connect/auth" +
               "?client_id=bff&response_type=code" +
               "&redirect_uri=" + [System.Uri]::EscapeDataString("$EdgeUrl/auth/callback")
        $got429 = $false
        for ($i = 0; $i -lt 15; $i++) {
            if ((Invoke-Http $url).StatusCode -eq 429) { $got429 = $true; break }
        }
        if (-not $got429) { throw "429 не появился за 15 запросов" }
    }
}

# ══════════════════════════════════════════════════════════════
#  ЗАПУСК
# ══════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor White
Write-Host "║       IAM Smoke Tests — Phase 0                       ║" -ForegroundColor White
Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor White
Write-Host "  Edge:    $EdgeUrl"
Write-Host "  Project: $Project  (префикс контейнеров)"
Write-Host "  Env:     $EnvFile"
Write-Host "  Group:   $Group"

if (-not (Test-Path $EnvFile)) {
    Write-Host ""
    Write-Host "  ⚠️  Файл $EnvFile не найден." -ForegroundColor Yellow
    Write-Host "     Запусти скрипт из корня репозитория (папка PMServices)" -ForegroundColor Yellow
    exit 1
}

switch ($Group) {
    "Compose"    { Test-Compose    }
    "Containers" { Test-Containers }
    "Edge"       { Test-Edge       }
    "Keycloak"   { Test-Keycloak   }
    "Database"   { Test-Database   }
    "Redis"      { Test-Redis      }
    "Mailpit"    { Test-Mailpit    }
    "RateLimit"  { Test-RateLimit  }
    default {
        Test-Compose
        Test-Containers
        Test-Edge
        Test-Keycloak
        Test-Database
        Test-Redis
        Test-Mailpit
        Test-RateLimit
    }
}

# ── Итог ──────────────────────────────────────────────────────
$total = $Pass + $Fail
$color = if ($Fail -eq 0) { "Green" } else { "Yellow" }
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor White
Write-Host ("  Итого: {0}   ✅ {1} passed   ❌ {2} failed" -f $total, $Pass, $Fail) -ForegroundColor $color

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "  Провалившиеся тесты:" -ForegroundColor Red
    $Errors | ForEach-Object { Write-Host "    • $_" -ForegroundColor DarkRed }
}

Write-Host ""
exit $(if ($Fail -eq 0) { 0 } else { 1 })
