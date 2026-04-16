<#
.SYNOPSIS
    Управление IAM dev окружением — один скрипт вместо длинных docker команд.

.DESCRIPTION
    Запускается из КОРНЯ репозитория (рядом с PMPlatform.slnx):
        .\ops\iam\iam.ps1 <команда>

.EXAMPLE
    .\ops\iam\iam.ps1 up           # Инфра + .NET сервисы (без observability)
    .\ops\iam\iam.ps1 observ       # Всё включая Grafana/Kibana/Prometheus
    .\ops\iam\iam.ps1 down         # Остановить всё
    .\ops\iam\iam.ps1 logs bff     # Логи конкретного сервиса
    .\ops\iam\iam.ps1 test         # Прогнать smoke тесты
    .\ops\iam\iam.ps1 test Edge    # Прогнать конкретную группу тестов
    .\ops\iam\iam.ps1 ui           # Открыть в браузере все UI
    .\ops\iam\iam.ps1 ps           # Статус контейнеров
    .\ops\iam\iam.ps1 restart bff  # Перезапустить сервис
    .\ops\iam\iam.ps1 build bff    # Пересобрать образ и перезапустить
#>

param(
    [Parameter(Position = 0, Mandatory = $false)]
    [ValidateSet("up","observ","down","logs","test","ui","ps","restart","build","help","infra")]
    [string]$Command = "help",

    # Переименовано из $Args — $Args конфликтует с автоматической переменной PowerShell
    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$ExtraArgs = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ─── Проверка что запускаем из корня репо ─────────────────────
if (-not (Test-Path "PMPlatform.slnx") -and -not (Test-Path "PMPlatform.sln")) {
    Write-Host "❌ Запускай из корня репозитория (рядом с PMPlatform.slnx)" -ForegroundColor Red
    exit 1
}

# ─── Читаем .env.iam для динамических URL ─────────────────────
$EnvFile = "ops\iam\.env.iam"

function Read-EnvFile([string]$Path) {
    $result = @{}
    if (Test-Path $Path) {
        Get-Content $Path | Where-Object { $_ -match '^([^#=]+)=(.+)$' } | ForEach-Object {
            $result[$Matches[1].Trim()] = $Matches[2].Trim().Trim('"').Trim("'")
        }
    }
    return $result
}

$EnvVars  = Read-EnvFile $EnvFile
$EdgePort = if ($EnvVars["EDGE_HTTP_PORT"])   { $EnvVars["EDGE_HTTP_PORT"] }   else { "8090" }
$MailPort = if ($EnvVars["MAILPIT_WEB_PORT"]) { $EnvVars["MAILPIT_WEB_PORT"] } else { "8025" }

# ─── Compose файлы ────────────────────────────────────────────
$Base   = "ops\iam\compose.iam.yml"
$Dev    = "ops\iam\compose.iam.dev.yml"
$Observ = "ops\iam\compose.iam.observ.yml"

$ComposeInfra  = "docker compose -f $Base --env-file $EnvFile"
$ComposeDev    = "docker compose -f $Base -f $Dev --env-file $EnvFile"
$ComposeObserv = "docker compose -f $Base -f $Dev -f $Observ --env-file $EnvFile"

# ─── Хелпер для запуска docker compose команд ─────────────────
function Invoke-Compose([string]$Cmd, [string]$CmdArgs = "") {
    $full = "$Cmd $CmdArgs"
    Write-Host "▶ $full" -ForegroundColor DarkGray
    Invoke-Expression $full
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        Write-Host "❌ Команда завершилась с кодом $LASTEXITCODE" -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

# ─── Команды ──────────────────────────────────────────────────
switch ($Command) {

    "infra" {
        Write-Host "🏗  Запуск инфраструктуры (postgres, redis, keycloak, mailpit, edge)..." -ForegroundColor Cyan
        Invoke-Compose $ComposeInfra "up -d"
        Write-Host ""
        Write-Host "✅ Инфра запущена. .NET сервисы не запущены." -ForegroundColor Green
        Write-Host "   Edge: http://localhost:$EdgePort"
    }

    "up" {
       Write-Host "🚀 Запуск dev окружения (инфра + bff + iam-api в runtime container режиме)..." -ForegroundColor Cyan
       Write-Host "   Без observability. Для observability: .\ops\iam\iam.ps1 observ" -ForegroundColor DarkGray
            Invoke-Compose $ComposeDev "up -d"
       Write-Host ""
       Write-Host "✅ Dev окружение запущено." -ForegroundColor Green
       Write-Host "   Edge:     http://localhost:$EdgePort"
       Write-Host "   BFF:      ASP.NET Core runtime container"
       Write-Host "   IAM API:  ASP.NET Core runtime container"
       Write-Host ""
       Write-Host "   Логи BFF:     .\ops\iam\iam.ps1 logs bff"
       Write-Host "   Логи IAM API: .\ops\iam\iam.ps1 logs iam-api"
    }

    "observ" {
        Write-Host "🔭 Запуск ПОЛНОГО окружения (dev + observability stack)..." -ForegroundColor Cyan
        Write-Host "   Elasticsearch + Kibana + Prometheus + Grafana + OTel Collector"
        Write-Host "   ⚠ Требует ~2.5GB RAM для Elasticsearch" -ForegroundColor Yellow
        Invoke-Compose $ComposeObserv "up -d"
        Write-Host ""
        Write-Host "✅ Всё запущено!" -ForegroundColor Green
        Write-Host "   Edge:       http://localhost:$EdgePort"
        Write-Host "   Grafana:    http://localhost:3000  (admin/admin)"
        Write-Host "   Kibana:     http://localhost:5601"
        Write-Host "   Prometheus: http://localhost:9090"
        Write-Host ""
        Write-Host "   .\ops\iam\iam.ps1 ui  — открыть всё в браузере"
    }

    "down" {
        Write-Host "🛑 Останавливаем всё..." -ForegroundColor Yellow
        Invoke-Compose $ComposeObserv "down"
        Write-Host "✅ Всё остановлено. Данные сохранены в volumes." -ForegroundColor Green
    }

    "logs" {
        $service = if ($ExtraArgs.Length -gt 0) { $ExtraArgs[0] } else { "" }
        if ($service) {
            Write-Host "📋 Логи: $service (Ctrl+C для выхода)" -ForegroundColor Cyan
            Invoke-Compose $ComposeObserv "logs -f $service"
        } else {
            Write-Host "📋 Логи всех сервисов (Ctrl+C для выхода)" -ForegroundColor Cyan
            Invoke-Compose $ComposeObserv "logs -f"
        }
    }

    "test" {
        Write-Host "🧪 Запуск smoke тестов..." -ForegroundColor Cyan
        if (-not (Test-Path "Test-IamInfra.ps1")) {
            Write-Host "❌ Test-IamInfra.ps1 не найден в корне репозитория" -ForegroundColor Red
            exit 1
        }
        if ($ExtraArgs.Length -gt 0) {
            & ".\Test-IamInfra.ps1" -Group $ExtraArgs[0]
        } else {
            & ".\Test-IamInfra.ps1"
        }
    }

    "ui" {
        Write-Host "🌐 Открываю UI в браузере..." -ForegroundColor Cyan
        $urls = @(
            @{ Name = "Edge";       Url = "http://localhost:$EdgePort" },
            @{ Name = "Grafana";    Url = "http://localhost:3000" },
            @{ Name = "Kibana";     Url = "http://localhost:5601" },
            @{ Name = "Prometheus"; Url = "http://localhost:9090" },
            @{ Name = "Mailpit";    Url = "http://localhost:$MailPort" }
        )
        foreach ($u in $urls) {
            Write-Host "  → $($u.Name): $($u.Url)"
            Start-Process $u.Url
            Start-Sleep -Milliseconds 300
        }
    }

    "ps" {
        Write-Host "📊 Статус контейнеров:" -ForegroundColor Cyan
        Invoke-Compose $ComposeObserv "ps"
    }

    "restart" {
        if ($ExtraArgs.Length -eq 0) {
            Write-Host "❌ Укажи сервис: .\ops\iam\iam.ps1 restart bff" -ForegroundColor Red
            exit 1
        }
        $service = $ExtraArgs[0]
        Write-Host "🔄 Перезапуск: $service" -ForegroundColor Cyan
        Invoke-Compose $ComposeObserv "restart $service"
    }

    "build" {
        if ($ExtraArgs.Length -gt 0) {
            $service = $ExtraArgs[0]
            Write-Host "🔨 Пересборка и перезапуск: $service" -ForegroundColor Cyan
            Invoke-Compose $ComposeDev "up -d --build $service"
        } else {
            Write-Host "🔨 Пересборка и перезапуск всех сервисов..." -ForegroundColor Cyan
            Invoke-Compose $ComposeDev "up -d --build"
        }
    }

    "help" {
        Write-Host ""
        Write-Host "IAM dev helper — запускай из корня репозитория" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  КОМАНДЫ:" -ForegroundColor White
        Write-Host "    infra            Только инфраструктура (postgres, redis, keycloak, mailpit)"
        Write-Host "    up               Инфра + BFF + IAM API в runtime container режиме"
        Write-Host "    observ           Всё: dev + Grafana/Kibana/Prometheus/OTel"
        Write-Host "    down             Остановить всё (данные в volumes сохраняются)"
        Write-Host "    logs [service]   Следить за логами (без сервиса — все)"
        Write-Host "    test [group]     Прогнать smoke тесты (группы: Edge Keycloak Database Redis)"
        Write-Host "    ui               Открыть все UI в браузере"
        Write-Host "    ps               Статус контейнеров"
        Write-Host "    restart <svc>    Перезапустить сервис"
        Write-Host "    build [svc]      Пересобрать образ и перезапустить"
        Write-Host ""
        Write-Host "  ПРИМЕРЫ:" -ForegroundColor White
        Write-Host "    .\ops\iam\iam.ps1 infra"
        Write-Host "    .\ops\iam\iam.ps1 up"
        Write-Host "    .\ops\iam\iam.ps1 observ"
        Write-Host "    .\ops\iam\iam.ps1 logs bff"
        Write-Host "    .\ops\iam\iam.ps1 test"
        Write-Host "    .\ops\iam\iam.ps1 test Edge"
        Write-Host "    .\ops\iam\iam.ps1 restart iam-api"
        Write-Host ""
    }
}
