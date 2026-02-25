# dump-structure.ps1 (PowerShell 5.1 compatible)
$Root = "C:\Users\89263\Desktop\Project\ProjectPlatform\PMServices"
$Log  = Join-Path $Root "_repo-structure.txt"

"PMServices repo structure dump" | Out-File -FilePath $Log -Encoding UTF8
("Timestamp: {0}" -f (Get-Date)) | Out-File -FilePath $Log -Append -Encoding UTF8
("Root: {0}" -f $Root) | Out-File -FilePath $Log -Append -Encoding UTF8
"" | Out-File -FilePath $Log -Append -Encoding UTF8

"==== TREE (directories + files) ====" | Out-File -FilePath $Log -Append -Encoding UTF8

Get-ChildItem -Path $Root -Force -Recurse |
  Sort-Object FullName |
  ForEach-Object {
    $rel = $_.FullName.Substring($Root.Length).TrimStart('\')
    $depth = ($rel -split '\\').Count - 1
    $indent = ("  " * $depth)
    $type = if ($_.PSIsContainer) { "[D]" } else { "[F]" }
    "{0}{1} {2}" -f $indent, $type, $rel
  } | Out-File -FilePath $Log -Append -Encoding UTF8

"" | Out-File -FilePath $Log -Append -Encoding UTF8
"==== CHECKS (variant B assumptions) ====" | Out-File -FilePath $Log -Append -Encoding UTF8

$OpsDir     = Join-Path $Root "ops"
$BackendDir = Join-Path $Root "backend"

$checks = @(
  @{ Name = "ops folder exists"; Path = $OpsDir },
  @{ Name = "backend folder exists"; Path = $BackendDir },
  @{ Name = "ops/compose.yml exists"; Path = (Join-Path $OpsDir "compose.yml") },
  @{ Name = "ops/.env.example exists"; Path = (Join-Path $OpsDir ".env.example") },
  @{ Name = "backend/Dockerfile exists"; Path = (Join-Path $BackendDir "Dockerfile") },
  @{ Name = "backend/PMServices.sln exists"; Path = (Join-Path $BackendDir "PMServices.sln") },
  @{ Name = "backend/src/PMServices/PMServices.csproj exists"; Path = (Join-Path $BackendDir "src\PMServices\PMServices.csproj") }
)

foreach ($c in $checks) {
  $ok = Test-Path $c.Path
  $status = if ($ok) { "OK" } else { "MISSING" }
  "{0,-45} : {1} ({2})" -f $c.Name, $status, $c.Path |
    Out-File -FilePath $Log -Append -Encoding UTF8
}

"" | Out-File -FilePath $Log -Append -Encoding UTF8
"==== TOP LEVEL ====" | Out-File -FilePath $Log -Append -Encoding UTF8

Get-ChildItem -Path $Root -Force |
  Sort-Object Name |
  ForEach-Object {
    $type = if ($_.PSIsContainer) { "[D]" } else { "[F]" }
    "{0} {1}" -f $type, $_.Name
  } | Out-File -FilePath $Log -Append -Encoding UTF8

"" | Out-File -FilePath $Log -Append -Encoding UTF8
"Done. Log saved to: $Log" | Out-File -FilePath $Log -Append -Encoding UTF8

Write-Host "Готово! Лог сохранён сюда: $Log"
Write-Host "Пришли сюда блоки: CHECKS и TOP LEVEL (можно целиком файл)."