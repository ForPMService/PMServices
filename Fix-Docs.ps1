$ErrorActionPreference = "Stop"
$docsRoot = "docs"

Write-Host "🩹 Начинаю лечение документации..." -ForegroundColor Cyan

# 1. Создание недостающих файлов (Заглушки)
# Список файлов, на которые ругается WARNING (not found in documentation files)
$missingFiles = @(
    "infra/keycloak-setup.md",
    "infra/env-config.md",
    "adr/index.md",
    "adr/0001-tenancy-model.md",
    "adr/0002-rbac-placement.md",
    "adr/0003-token-storage-spa.md"
)

foreach ($file in $missingFiles) {
    $fullPath = Join-Path $docsRoot $file
    $parentDir = Split-Path $fullPath
    
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    if (-not (Test-Path $fullPath)) {
        "# Заглушка для $file`n`nЭтот файл еще не написан." | Set-Content -Path $fullPath -Encoding UTF8
        Write-Host "[+] Создана заглушка: $file" -ForegroundColor Green
    }
}

# 2. Карта замен (Старое -> Новое)
# Важно: Сначала меняем специфичные имена файлов, потом папки
$replacements = @{
    # Имена файлов (которые переименовали)
    "01-Context-C4.md"      = "c4-context.md"
    "02-Containers-C4.md"   = "c4-containers.md"
    "03-Auth-Overview.md"   = "auth-overview.md"
    "04-Security.md"        = "security.md"
    "01-Architecture.md"    = "architecture.md"
    "02-Database.md"        = "database.md"
    "03-Migrations.md"      = "migrations.md"
    "04-Events.md"          = "events.md"
    "02-Auth.md"            = "auth.md"
    "03-API.md"             = "api.md"
    "01-Overview.md"        = "overview.md"
    "openapi-ref.md"        = "api/openapi-ref.md" # Уточнение пути
    "01-Local-Dev.md"       = "local-dev.md"
    "02-Keycloak-Setup.md"  = "keycloak-setup.md"
    "03-Env-Config.md"      = "env-config.md"
    "05-Observability.md"   = "observability.md"
    "06-Email.md"           = "email.md"
    "PLAN.md"               = "plan.md"
    "PROMPTS.md"            = "prompts.md"
    "00-Index.md"           = "index.md"

    # Папки (глобальная замена путей)
    "03-Architecture/"      = "architecture/"
    "04-Backend/"           = "backend/"
    "05-Frontend/"          = "frontend/"
    "06-Modules/IAM/"       = "modules/iam/"
    "06-Modules/_template/" = "modules/_template/"
    "07-Infra/"             = "infra/"
    "90-ADR/"               = "adr/"
}

# 3. Проход по всем файлам и замена текста
$files = Get-ChildItem -Path $docsRoot -Recurse -Filter "*.md"

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $newContent = $content
    $modified = $false

    foreach ($key in $replacements.Keys) {
        if ($newContent -match [regex]::Escape($key)) {
            $newContent = $newContent -replace [regex]::Escape($key), $replacements[$key]
            $modified = $true
        }
    }

    if ($modified) {
        Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
        Write-Host "[*] Исправлены ссылки в: $($file.Name)" -ForegroundColor Yellow
    }
}

Write-Host "`n✅ Готово! Попробуйте запустить 'mkdocs build' снова." -ForegroundColor Cyan