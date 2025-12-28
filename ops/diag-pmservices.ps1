<# 
diag-pmservices.ps1
Запуск из папки ops:
  powershell -ExecutionPolicy Bypass -File .\diag-pmservices.ps1
  pwsh -File .\diag-pmservices.ps1

Опции:
  -HttpTimeoutSec 5
  -IncludeLogs
  -LogsTail 120
#>

param(
    [int]$HttpTimeoutSec = 5,
    [int]$LogsTail = 120,
    [switch]$IncludeLogs
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

function Step([string]$Text) {
    Write-Host ("`n=== " + $Text + " ===") -ForegroundColor Cyan
}

function New-Row {
    param(
        [string]$Area,
        [string]$Check,
        [string]$Target,
        [string]$Status,
        [string]$Details
    )
    [PSCustomObject]@{
        Time    = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Area    = $Area
        Check   = $Check
        Target  = $Target
        Status  = $Status
        Details = $Details
    }
}

function Mask-SecretValue {
    param([string]$Key, [string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $Value }

    if ($Key -match '(PASSWORD|SECRET|TOKEN|KEY)' -or $Key -match '(ClientSecret|AdminPassword)') {
        if ($Value.Length -le 4) { return "****" }
        return ($Value.Substring(0,2) + "****" + $Value.Substring($Value.Length-2,2))
    }
    return $Value
}

function Try-Run {
    param([scriptblock]$Block)
    try {
        $out = & $Block
        return @{ Ok=$true; Out=$out }
    } catch {
        return @{ Ok=$false; Out=$_.Exception.Message }
    }
}

function Run-Docker {
    <#
      Важно: НЕ склеиваем аргументы строкой.
      Вызываем docker с массивом аргументов, чтобы пробелы в аргументах не ломались.
      stdout/stderr пишем во временные файлы.
    #>
    param([string[]]$Arguments)

    $stdoutFile = [System.IO.Path]::GetTempFileName()
    $stderrFile = [System.IO.Path]::GetTempFileName()

    try {
        & docker @Arguments 1> $stdoutFile 2> $stderrFile
        $code = $LASTEXITCODE

        $stdout = Get-Content $stdoutFile -Raw -ErrorAction SilentlyContinue
        $stderr = Get-Content $stderrFile -Raw -ErrorAction SilentlyContinue

        if ($null -eq $stdout) { $stdout = "" }
        if ($null -eq $stderr) { $stderr = "" }

        return @{
            Code   = $code
            Stdout = $stdout.TrimEnd()
            Stderr = $stderr.TrimEnd()
        }
    }
    finally {
        Remove-Item $stdoutFile -Force -ErrorAction SilentlyContinue | Out-Null
        Remove-Item $stderrFile -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

function Get-Prop($obj, [string]$name) {
    if ($null -eq $obj) { return $null }
    $p = $obj.PSObject.Properties[$name]
    if ($null -eq $p) { return $null }
    return $p.Value
}

function Http-Check {
    <#
      Работает в Windows PowerShell 5.1 и в PowerShell 7+.
      Любой HTTP-ответ (включая 404/401/500) = "reachable" (WARN), не FAIL.
    #>
    param(
        [string]$Url,
        [int]$TimeoutSec = 5
    )

    try {
        $req = [System.Net.HttpWebRequest][System.Net.WebRequest]::Create($Url)
        $req.Method = "GET"
        $req.Timeout = $TimeoutSec * 1000
        $req.ReadWriteTimeout = $TimeoutSec * 1000
        $req.AllowAutoRedirect = $true

        $resp = [System.Net.HttpWebResponse]$req.GetResponse()
        $code = [int]$resp.StatusCode
        $reason = $resp.StatusDescription
        $resp.Close()

        return @{ Ok=$true; Code=$code; Info=$reason }
    }
    catch [System.Net.WebException] {
        $we = $_.Exception
        if ($we.Response -ne $null) {
            $resp = [System.Net.HttpWebResponse]$we.Response
            $code = [int]$resp.StatusCode
            $reason = $resp.StatusDescription
            $resp.Close()
            return @{ Ok=$true; Code=$code; Info="HTTP error but reachable" }
        }
        return @{ Ok=$false; Code=$null; Info=$we.Message }
    }
    catch {
        return @{ Ok=$false; Code=$null; Info=$_.Exception.Message }
    }
}

# ------------------------------------------------------------
# Основная логика
# ------------------------------------------------------------
$rows = New-Object System.Collections.Generic.List[object]

Step "Docker versions"
$ver = Try-Run { Run-Docker @("--version") }
if ($ver.Ok -and $ver.Out.Code -eq 0) {
    $rows.Add((New-Row "Docker" "docker --version" "local" "OK" $ver.Out.Stdout))
} else {
    $msg = if ($ver.Ok) { $ver.Out.Stderr } else { $ver.Out }
    $rows.Add((New-Row "Docker" "docker --version" "local" "FAIL" $msg))
    $rows | Format-Table -AutoSize
    exit 1
}

$composeVer = Try-Run { Run-Docker @("compose","version") }
if ($composeVer.Ok -and $composeVer.Out.Code -eq 0) {
    $rows.Add((New-Row "Docker" "docker compose version" "local" "OK" $composeVer.Out.Stdout))
} else {
    $msg = if ($composeVer.Ok) { $composeVer.Out.Stderr } else { $composeVer.Out }
    $rows.Add((New-Row "Docker" "docker compose version" "local" "FAIL" $msg))
    $rows | Format-Table -AutoSize
    exit 1
}

Step "Load .env"
$envPath = Join-Path (Get-Location) ".env"
$envMap = @{}
if (Test-Path $envPath) {
    $lines = Get-Content $envPath -ErrorAction SilentlyContinue
    foreach ($l in $lines) {
        $t = $l.Trim()
        if ($t -eq "" -or $t.StartsWith("#")) { continue }
        $idx = $t.IndexOf("=")
        if ($idx -lt 1) { continue }
        $k = $t.Substring(0,$idx).Trim()
        $v = $t.Substring($idx+1).Trim()
        $envMap[$k] = $v
    }
    $rows.Add((New-Row "Config" ".env loaded" $envPath "OK" ("Keys: " + $envMap.Keys.Count)))
} else {
    $rows.Add((New-Row "Config" ".env loaded" $envPath "WARN" "No .env in current folder"))
}

$API_PORT    = if ($envMap.ContainsKey("API_HTTP_PORT")) { [int]$envMap["API_HTTP_PORT"] } else { 8080 }
$KC_PORT     = if ($envMap.ContainsKey("KEYCLOAK_HTTP_PORT")) { [int]$envMap["KEYCLOAK_HTTP_PORT"] } else { 8081 }
$MAILPIT_WEB = if ($envMap.ContainsKey("MAILPIT_WEB_PORT")) { [int]$envMap["MAILPIT_WEB_PORT"] } else { 8025 }

Step "Compose ps (json if possible)"
$containers = @()
$psJson = Try-Run { Run-Docker @("compose","ps","--format","json") }

if ($psJson.Ok -and $psJson.Out.Code -eq 0 -and $psJson.Out.Stdout) {
    try {
        $raw = $psJson.Out.Stdout | ConvertFrom-Json
        if ($raw -isnot [array]) { $containers = @($raw) } else { $containers = $raw }
        $rows.Add((New-Row "Compose" "compose ps" "project" "OK" "Parsed JSON"))
    } catch {
        $rows.Add((New-Row "Compose" "compose ps" "project" "WARN" "JSON parse failed, using text output"))
        $containers = @()
    }
} else {
    $rows.Add((New-Row "Compose" "compose ps" "project" "WARN" "No JSON/empty, using text output"))
}

if (-not $containers -or $containers.Count -eq 0) {
    $psText = Run-Docker @("compose","ps")
    if ($psText.Code -ne 0) {
        $rows.Add((New-Row "Compose" "compose ps" "project" "FAIL" $psText.Stderr))
    } else {
        $rows.Add((New-Row "Compose" "compose ps" "project" "OK" "Text output captured"))
        $rows.Add((New-Row "Compose" "compose ps raw" "project" "INFO" ($psText.Stdout -replace "\r","")))
    }
} else {
    foreach ($c in $containers) {
        $svc    = Get-Prop $c "Service"
        $name   = Get-Prop $c "Name"
        $state  = Get-Prop $c "State"
        $health = Get-Prop $c "Health"
        $pub    = Get-Prop $c "Publishers"

        $portInfo = ""
        if ($pub) {
            $portInfo = ($pub | ForEach-Object { "$($_.PublishedPort)->$($_.TargetPort)/$($_.Protocol)" }) -join ", "
        }

        $st = if ($state -eq "running") { "OK" } else { "FAIL" }
        $det = "state=$state"
        if ($health) { $det += "; health=$health" }
        if ($portInfo) { $det += "; ports=$portInfo" }

        $rows.Add((New-Row "Containers" "service status" "$svc ($name)" $st $det))
    }
}

# Определим, запущены ли observability сервисы (чтобы не пугать FAIL)
$hasEs = $false
$hasKb = $false
if ($containers -and $containers.Count -gt 0) {
    $hasEs = (($containers | Where-Object { (Get-Prop $_ "Service") -eq "elasticsearch" }).Count -gt 0)
    $hasKb = (($containers | Where-Object { (Get-Prop $_ "Service") -eq "kibana" }).Count -gt 0)
}

Step "HTTP checks"
$checksHttp = @(
    @{ Area="HTTP"; Check="API /";          Target="http://localhost:$API_PORT/";                   Url="http://localhost:$API_PORT/" },
    @{ Area="HTTP"; Check="API swagger";    Target="http://localhost:$API_PORT/swagger/index.html"; Url="http://localhost:$API_PORT/swagger/index.html" },
    @{ Area="HTTP"; Check="Keycloak /";     Target="http://localhost:$KC_PORT/";                    Url="http://localhost:$KC_PORT/" },
    @{ Area="HTTP"; Check="Keycloak ready"; Target="http://localhost:$KC_PORT/health/ready";        Url="http://localhost:$KC_PORT/health/ready" },
    @{ Area="HTTP"; Check="Mailpit /";      Target="http://localhost:$MAILPIT_WEB/";                Url="http://localhost:$MAILPIT_WEB/" }
)

if ($hasEs) {
    $checksHttp += @{ Area="HTTP"; Check="Elasticsearch"; Target="http://localhost:9200/"; Url="http://localhost:9200/" }
} else {
    $rows.Add((New-Row "HTTP" "Elasticsearch" "http://localhost:9200/" "SKIP" "Not running (profile observability not enabled)"))
}

if ($hasKb) {
    $checksHttp += @{ Area="HTTP"; Check="Kibana"; Target="http://localhost:5601/"; Url="http://localhost:5601/" }
} else {
    $rows.Add((New-Row "HTTP" "Kibana" "http://localhost:5601/" "SKIP" "Not running (profile observability not enabled)"))
}

foreach ($hc in $checksHttp) {
    $r = Http-Check -Url $hc.Url -TimeoutSec $HttpTimeoutSec
    if ($r.Ok) {
        $status = "OK"
        if ($r.Code -ge 400) { $status = "WARN" } # сервер ответил, но endpoint не тот/нужна авторизация
        $rows.Add((New-Row $hc.Area $hc.Check $hc.Target $status ("HTTP " + $r.Code + " (" + $r.Info + ")")))
    } else {
        $rows.Add((New-Row $hc.Area $hc.Check $hc.Target "FAIL" $r.Info))
    }
}

Step "Exec checks"
# Redis ping
$redisPing = Try-Run { Run-Docker @("compose","exec","-T","redis","redis-cli","ping") }
if ($redisPing.Ok -and $redisPing.Out.Code -eq 0) {
    $ok = $redisPing.Out.Stdout -match "PONG"
    $rows.Add((New-Row "Exec" "Redis ping" "redis" ($(if ($ok) {"OK"} else {"WARN"})) $redisPing.Out.Stdout))
} else {
    $msg = if ($redisPing.Ok) { $redisPing.Out.Stderr } else { $redisPing.Out }
    $rows.Add((New-Row "Exec" "Redis ping" "redis" "FAIL" $msg))
}

# Postgres app select 1 (ключ -w чтобы не зависнуть на запросе пароля)
$pgApp = Try-Run { Run-Docker @("compose","exec","-T","postgres-app","psql","-w","-U","pmservices","-d","pmservices","-c","select 1;") }
if ($pgApp.Ok -and $pgApp.Out.Code -eq 0) {
    $rows.Add((New-Row "Exec" "Postgres app select" "postgres-app" "OK" "select 1 OK"))
} else {
    $msg = if ($pgApp.Ok) { $pgApp.Out.Stderr } else { $pgApp.Out }
    $rows.Add((New-Row "Exec" "Postgres app select" "postgres-app" "FAIL" $msg))
}

# Postgres keycloak select 1
$pgKc = Try-Run { Run-Docker @("compose","exec","-T","postgres-keycloak","psql","-w","-U","keycloak","-d","keycloak","-c","select 1;") }
if ($pgKc.Ok -and $pgKc.Out.Code -eq 0) {
    $rows.Add((New-Row "Exec" "Postgres keycloak select" "postgres-keycloak" "OK" "select 1 OK"))
} else {
    $msg = if ($pgKc.Ok) { $pgKc.Out.Stderr } else { $pgKc.Out }
    $rows.Add((New-Row "Exec" "Postgres keycloak select" "postgres-keycloak" "FAIL" $msg))
}

# API env snapshot (filtered)
$apiEnv = Try-Run { Run-Docker @("compose","exec","-T","api","printenv") }
if ($apiEnv.Ok -and $apiEnv.Out.Code -eq 0) {
    $lines = $apiEnv.Out.Stdout -split "`n"
    $interesting = @()
    foreach ($ln in $lines) {
        if ($ln -match "^(ASPNET|ConnectionStrings__|Keycloak__|Redis__|Smtp__)" ) {
            $parts = $ln.Split("=",2)
            if ($parts.Count -eq 2) {
                $k = $parts[0]
                $v = $parts[1]
                $v2 = Mask-SecretValue -Key $k -Value $v
                $interesting += ("$k=$v2")
            }
        }
    }
    $rows.Add((New-Row "Exec" "API env (filtered)" "api" "OK" (($interesting -join "; "))))
} else {
    $msg = if ($apiEnv.Ok) { $apiEnv.Out.Stderr } else { $apiEnv.Out }
    $rows.Add((New-Row "Exec" "API env (filtered)" "api" "FAIL" $msg))
}

Step "Optional logs"
if ($IncludeLogs) {
    foreach ($svc in @("api","keycloak","postgres-app","postgres-keycloak","redis","mailpit")) {
        $lg = Try-Run { Run-Docker @("compose","logs","--tail",$LogsTail.ToString(),$svc) }
        if ($lg.Ok -and $lg.Out.Code -eq 0) {
            $rows.Add((New-Row "Logs" "tail" $svc "INFO" ("tail=" + $LogsTail + " captured")))
        } else {
            $msg = if ($lg.Ok) { $lg.Out.Stderr } else { $lg.Out }
            $rows.Add((New-Row "Logs" "tail" $svc "WARN" $msg))
        }
    }
}

Step "Report"
$reportDir = (Get-Location).Path
$stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
$csvPath  = Join-Path $reportDir ("_diag-" + $stamp + ".csv")
$jsonPath = Join-Path $reportDir ("_diag-" + $stamp + ".json")
$txtPath  = Join-Path $reportDir ("_diag-" + $stamp + ".txt")

$rowsSorted = $rows | Sort-Object Area, Check, Target

$rowsSorted | Format-Table -AutoSize

$rowsSorted | Export-Csv -NoTypeInformation -Encoding UTF8 $csvPath
$rowsSorted | ConvertTo-Json -Depth 6 | Out-File -Encoding UTF8 $jsonPath

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("PMServices diagnostics: $stamp")
[void]$sb.AppendLine("Folder: $reportDir")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("=== TABLE ===")
[void]$sb.AppendLine(($rowsSorted | Format-Table -AutoSize | Out-String))

$psRaw = Run-Docker @("compose","ps")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("=== docker compose ps ===")
[void]$sb.AppendLine($psRaw.Stdout)

$sb.ToString() | Out-File -Encoding UTF8 $txtPath

Write-Host ""
Write-Host "Saved:"
Write-Host (" - " + $csvPath)
Write-Host (" - " + $jsonPath)
Write-Host (" - " + $txtPath)