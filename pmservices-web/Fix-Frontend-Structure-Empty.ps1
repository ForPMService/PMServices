# Fix-Frontend-Structure-Empty.ps1
# Подготовка "чистого листа" для внедрения OIDC

Write-Host "🚀 Начинаем создание структуры с пустыми файлами..." -ForegroundColor Cyan

# 1. Исправление зависимостей
Write-Host "📦 Обновляем NPM пакеты..." -ForegroundColor Yellow
npm uninstall keycloak-js
npm install angular-auth-oidc-client
Write-Host "✅ Зависимости обновлены." -ForegroundColor Green

# 2. Удаление старых файлов (Keycloak adapter)
$filesToRemove = @(
    "src/app/core/auth/keycloak.config.ts",
    "src/app/core/auth/auth.service.ts"
)
foreach ($file in $filesToRemove) {
    if (Test-Path $file) {
        Remove-Item $file -Force
        Write-Host "🗑️ Удален старый файл: $file" -ForegroundColor Gray
    }
}

# 3. Переименование файлов компонента (если они еще не переименованы)
if (Test-Path "src/app/app.ts") {
    Move-Item "src/app/app.ts" "src/app/app.component.ts" -Force
    Write-Host "🔄 Renamed: app.ts -> app.component.ts" -ForegroundColor Gray
}
if (Test-Path "src/app/app.html") {
    Move-Item "src/app/app.html" "src/app/app.component.html" -Force
    Write-Host "🔄 Renamed: app.html -> app.component.html" -ForegroundColor Gray
}
if (Test-Path "src/app/app.scss") {
    Move-Item "src/app/app.scss" "src/app/app.component.scss" -Force
}

# 4. Создание структуры папок
New-Item -ItemType Directory -Force -Path "src/app/core/auth" | Out-Null
New-Item -ItemType Directory -Force -Path "src/app/core/guards" | Out-Null
New-Item -ItemType Directory -Force -Path "src/app/core/api" | Out-Null

# 5. Создание ПУСТЫХ файлов (заглушек) для последующего наполнения

$emptyMsg = "// TODO: Implement step-by-step"

# Auth Config
Set-Content -Path "src/app/core/auth/auth.config.ts" -Value $emptyMsg -Encoding UTF8
Write-Host "📄 Очищен/Создан: src/app/core/auth/auth.config.ts" -ForegroundColor Green

# App Config
Set-Content -Path "src/app/app.config.ts" -Value $emptyMsg -Encoding UTF8
Write-Host "📄 Очищен: src/app/app.config.ts" -ForegroundColor Green

# Main (Bootstrap)
Set-Content -Path "src/main.ts" -Value $emptyMsg -Encoding UTF8
Write-Host "📄 Очищен: src/main.ts" -ForegroundColor Green

# App Component (Logic)
Set-Content -Path "src/app/app.component.ts" -Value $emptyMsg -Encoding UTF8
Write-Host "📄 Очищен: src/app/app.component.ts" -ForegroundColor Green

# App Component (Template)
Set-Content -Path "src/app/app.component.html" -Value "" -Encoding UTF8
Write-Host "📄 Очищен: src/app/app.component.html" -ForegroundColor Green

Write-Host "🎉 Готово! Структура создана, файлы пусты. Жду команды на наполнение." -ForegroundColor Cyan