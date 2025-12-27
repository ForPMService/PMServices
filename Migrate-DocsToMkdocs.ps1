<#
.SYNOPSIS
    Миграция docs/ для MkDocs Material

.DESCRIPTION
    Переименовывает файлы, убирает числовые префиксы,
    создаёт структуру папок для MkDocs.

.EXAMPLE
    .\Migrate-DocsToMkdocs.ps1 -WhatIf
    .\Migrate-DocsToMkdocs.ps1
#>
param(
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

# Маппинг: старый путь → новый путь
$migrations = @{
    # Главная
    "00-Index.md"      = "index.md"
    "02-Glossary.md"   = "glossary.md"
    
    # Architecture
    "03-Architecture/00-Index.md"        = "architecture/index.md"
    "03-Architecture/01-Context-C4.md"   = "architecture/c4-context.md"
    "03-Architecture/02-Containers-C4.md"= "architecture/c4-containers.md"
    "03-Architecture/03-Auth-Overview.md"= "architecture/auth-overview.md"
    "03-Architecture/04-Security.md"     = "architecture/security.md"
    
    # Backend
    "04-Backend/00-Index.md"       = "backend/index.md"
    "04-Backend/01-Architecture.md"= "backend/architecture.md"
    "04-Backend/02-Database.md"    = "backend/database.md"
    "04-Backend/03-Migrations.md"  = "backend/migrations.md"
    "04-Backend/04-Events.md"      = "backend/events.md"
    
    # Frontend
    "05-Frontend/00-Index.md"       = "frontend/index.md"
    "05-Frontend/01-Architecture.md"= "frontend/architecture.md"
    "05-Frontend/02-Auth.md"        = "frontend/auth.md"
    "05-Frontend/03-API.md"         = "frontend/api.md"
    
    # Modules
    "06-Modules/IAM/00-Index.md"      = "modules/iam/index.md"
    "06-Modules/IAM/01-Overview.md"   = "modules/iam/overview.md"
    "06-Modules/IAM/api/openapi-ref.md"= "modules/iam/api/openapi-ref.md"
    "06-Modules/IAM/api/events.md"    = "modules/iam/api/events.md"
    "06-Modules/IAM/data/schema.md"   = "modules/iam/data/schema.md"
    "06-Modules/IAM/ui/routes.md"     = "modules/iam/ui/routes.md"
    "06-Modules/IAM/ui/pages.md"      = "modules/iam/ui/pages.md"
    "06-Modules/IAM/dev/PLAN.md"      = "modules/iam/dev/plan.md"
    "06-Modules/IAM/dev/PROMPTS.md"   = "modules/iam/dev/prompts.md"
    
    # Infra
    "07-Infra/00-Index.md"         = "infra/index.md"
    "07-Infra/01-Local-Dev.md"     = "infra/local-dev.md"
    "07-Infra/02-Keycloak-Setup.md"= "infra/keycloak-setup.md"
    "07-Infra/03-Env-Config.md"    = "infra/env-config.md"
    "07-Infra/05-Observability.md" = "infra/observability.md"
    "07-Infra/06-Email.md"         = "infra/email.md"
    
    # ADR
    "90-ADR/README.md"                = "adr/index.md"
    "90-ADR/0000-template.md"         = "adr/0000-template.md"
    "90-ADR/0001-tenancy-model.md"    = "adr/0001-tenancy-model.md"
    "90-ADR/0002-rbac-placement.md"   = "adr/0002-rbac-placement.md"
    "90-ADR/0003-token-storage-spa.md"= "adr/0003-token-storage-spa.md"
}

# Создаём modules/index.md (нет в оригинале)
$modulesIndex = @"
# Модули

Бизнес-модули платформы PMServices.

## Доступные модули

| Модуль | Статус | Описание |
|--------|--------|----------|
| [IAM](iam/index.md) | 🚧 В разработке | Identity & Access Management |
| Projects | 📋 Планируется | Управление проектами |
| Tasks | 📋 Планируется | Задачи и канбан |

## Структура модуля

Каждый модуль следует шаблону:

- ``index.md`` — обзор модуля
- ``api/`` — OpenAPI, события
- ``data/`` — схема БД
- ``ui/`` — роуты, страницы
- ``dev/`` — план, промпты для ИИ
"@

# Базовая директория docs
$docsRoot = "docs"

Write-Host "=== MkDocs Migration ===" -ForegroundColor Cyan
Write-Host "Docs root: $docsRoot"
Write-Host "Mode: $(if($WhatIf){'DRY RUN'}else{'EXECUTE'})"
Write-Host ""

# 1. Создаём новые директории
$newDirs = @(
    "architecture",
    "backend", 
    "frontend",
    "modules",
    "modules/iam",
    "modules/iam/api",
    "modules/iam/data",
    "modules/iam/ui",
    "modules/iam/dev",
    "infra",
    "adr"
)

foreach ($dir in $newDirs) {
    $path = Join-Path $docsRoot $dir
    if (-not (Test-Path $path)) {
        if ($WhatIf) {
            Write-Host "[DRY] Create dir: $path" -ForegroundColor Yellow
        } else {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
            Write-Host "[OK] Created: $path" -ForegroundColor Green
        }
    }
}

# 2. Копируем/переименовываем файлы
foreach ($entry in $migrations.GetEnumerator()) {
    $src = Join-Path $docsRoot $entry.Key
    $dst = Join-Path $docsRoot $entry.Value
    
    if (Test-Path $src) {
        if ($WhatIf) {
            Write-Host "[DRY] Move: $($entry.Key) -> $($entry.Value)" -ForegroundColor Yellow
        } else {
            # Создаём родительскую папку если нужно
            $dstDir = Split-Path $dst -Parent
            if (-not (Test-Path $dstDir)) {
                New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
            }
            Copy-Item -Path $src -Destination $dst -Force
            Write-Host "[OK] Moved: $($entry.Key) -> $($entry.Value)" -ForegroundColor Green
        }
    } else {
        Write-Host "[SKIP] Not found: $($entry.Key)" -ForegroundColor DarkGray
    }
}

# 3. Создаём modules/index.md
$modulesIndexPath = Join-Path $docsRoot "modules/index.md"
if ($WhatIf) {
    Write-Host "[DRY] Create: modules/index.md" -ForegroundColor Yellow
} else {
    $modulesIndex | Set-Content -Path $modulesIndexPath -Encoding UTF8
    Write-Host "[OK] Created: modules/index.md" -ForegroundColor Green
}

# 4. Копируем mkdocs.yml в корень
$mkdocsSource = "mkdocs.yml"  # Ожидаем рядом со скриптом
$mkdocsDest = "mkdocs.yml"
if (Test-Path $mkdocsSource) {
    if ($WhatIf) {
        Write-Host "[DRY] Copy mkdocs.yml to root" -ForegroundColor Yellow
    } else {
        Copy-Item $mkdocsSource $mkdocsDest -Force
        Write-Host "[OK] Copied mkdocs.yml" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan

if ($WhatIf) {
    Write-Host "Run without -WhatIf to apply changes." -ForegroundColor Yellow
} else {
    Write-Host @"
Migration complete!

Next steps:
1. Review new structure: Get-ChildItem docs -Recurse
2. Test locally: mkdocs serve
3. Delete old folders (after testing):
   - docs/03-Architecture/
   - docs/04-Backend/
   - docs/05-Frontend/
   - docs/06-Modules/
   - docs/07-Infra/
   - docs/90-ADR/
   - docs/00-Index.md
   - docs/02-Glossary.md

4. Commit and push to trigger GitHub Pages deploy
"@ -ForegroundColor Green
}
