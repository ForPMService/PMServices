# Reorganize-Final.ps1
$ErrorActionPreference = "Stop"
Write-Host "🚀 Начинаем реорганизацию по новой структуре..." -ForegroundColor Cyan

# --- 1. Создаем целевую структуру папок ---
$folders = @(
    "ops",
    "backend/src/PMServices",
    "backend/migrations",
    "docs",
    "pmservices-web"
)

foreach ($f in $folders) {
    if (-not (Test-Path $f)) {
        New-Item -ItemType Directory -Path $f | Out-Null
        Write-Host "📁 Создана папка: $f" -ForegroundColor Green
    }
}

# --- 2. Функция для поиска и перемещения файлов ---
function Move-File-Smart {
    param ($fileName, $destPath)
    
    # Ищем файл в корне, в backend/ или в старых местах
    $possiblePaths = @(
        ".\$fileName",
        "backend\$fileName",
        "backend\src\$fileName"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            # Если файл уже на месте - пропускаем
            if ((Resolve-Path $path).Path -eq (Resolve-Path "$destPath\$fileName" -ErrorAction SilentlyContinue).Path) {
                Write-Host "👌 $fileName уже на месте" -ForegroundColor Gray
                return
            }
            
            Move-Item -Path $path -Destination $destPath -Force
            Write-Host "📦 Перемещен: $fileName -> $destPath" -ForegroundColor Green
            return
        }
    }
    Write-Host "⚠️ Файл $fileName не найден для перемещения (возможно, его и не было)" -ForegroundColor Yellow
}

# --- 3. Перемещаем файлы .NET (Исходный код) ---
# Всё, что относится к коду, кладем в backend/src/PMServices
$codeFiles = @(
    "PMServices.csproj",
    "Program.cs",
    "appsettings.json",
    "appsettings.Development.json",
    "Properties",
    "bin",
    "obj"
)
foreach ($file in $codeFiles) {
    Move-File-Smart -fileName $file -destPath "backend/src/PMServices"
}

# --- 4. Перемещаем Dockerfile и инфраструктуру ---
# Dockerfile кладем в корень backend (как на схеме)
Move-File-Smart -fileName "Dockerfile" -destPath "backend"

# Compose кладем в ops
if (Test-Path "docker-compose.yml") { Move-Item "docker-compose.yml" "ops/compose.yml" }
if (Test-Path "compose.yml") { Move-Item "compose.yml" "ops/compose.yml" }
Move-File-Smart -fileName ".env" -destPath "ops"
Move-File-Smart -fileName ".env.example" -destPath "ops"

# --- 5. Исправляем .SLN (Файл решения) ---
Write-Host "🔧 Исправляем привязки в PMServices.sln..." -ForegroundColor Cyan
$slnFile = "PMServices.sln"

# Удаляем старые битые ссылки (по разным путям, которые могли быть)
dotnet sln $slnFile remove PMServices.csproj 2>$null
dotnet sln $slnFile remove backend/PMServices.csproj 2>$null
dotnet sln $slnFile remove backend/src/PMServices.csproj 2>$null

# Добавляем правильный путь
$projectPath = "backend/src/PMServices/PMServices.csproj"
if (Test-Path $projectPath) {
    dotnet sln $slnFile add $projectPath
    Write-Host "✅ Проект успешно привязан к решению: $projectPath" -ForegroundColor Green
} else {
    Write-Host "❌ ОШИБКА: Не удалось найти .csproj после перемещения!" -ForegroundColor Red
}

# --- 6. Исправляем ops/compose.yml ---
$composePath = "ops/compose.yml"
if (Test-Path $composePath) {
    $content = Get-Content $composePath -Raw
    
    # Обновляем контекст сборки для API
    # Было: context: ..  ИЛИ context: ./backend
    # Стало: context: ../backend
    # Dockerfile: Dockerfile (он теперь лежит прямо в backend)
    
    # Простая замена (регулярка ищет старые варианты)
    $newContent = $content -replace "context: \.\.", "context: ../backend" `
                           -replace "dockerfile: Dockerfile", "dockerfile: Dockerfile"

    Set-Content -Path $composePath -Value $newContent
    Write-Host "🐳 Обновлен ops/compose.yml (context -> ../backend)" -ForegroundColor Green
}

Write-Host "`n🎉 Готово! Структура приведена к идеалу." -ForegroundColor Cyan
Write-Host "ВАЖНО: Проверьте содержимое backend/Dockerfile. Пути COPY могут потребовать правки." -ForegroundColor Yellow