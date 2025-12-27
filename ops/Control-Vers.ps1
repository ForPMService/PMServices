$ErrorActionPreference = "Continue"

function Run([string]$title, [scriptblock]$cmd) {
  $out = & $cmd 2>&1
  $text = (($out | Out-String) -replace "\s+"," ").Trim()

  if ($LASTEXITCODE -ne 0) {
    Write-Host ("{0}: ERROR -> {1}" -f $title, $text)
  } else {
    Write-Host ("{0}: {1}" -f $title, $text)
  }
}

Write-Host "=== Compose status ==="
docker compose ps
Write-Host ""

Write-Host "=== Images (точные теги) ==="
docker compose images
Write-Host ""

Write-Host "=== Runtime versions ==="
Run "PostgreSQL" { docker compose exec -T db psql -U postgres -d postgres -tAc "select version();" }
Run "Redis"      { docker compose exec -T redis redis-server --version }

# Keycloak (kc.sh --version стабильно)
Run "Keycloak"   { docker compose exec -T keycloak /opt/keycloak/bin/kc.sh --version }

# Mailpit (бинарник /mailpit)
Run "Mailpit"    { docker compose exec -T mailpit /mailpit version }

# Nginx (версия уходит в stderr — мы уже забрали 2>&1)
Run "Nginx"      { docker compose exec -T web sh -lc "nginx -v 2>&1" }

# API/.NET: без SDK надёжнее --info / --list-runtimes
Run "API/.NET host"     { docker compose exec -T api dotnet --info | Select-String -Pattern "Host:" -Context 0,2 }
Run "API/.NET runtimes" { docker compose exec -T api dotnet --list-runtimes }

Write-Host "======================"