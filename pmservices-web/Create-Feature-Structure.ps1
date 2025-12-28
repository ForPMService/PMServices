# Create-Feature-Structure.ps1
# Генерация структуры компонентов (v2 - Safe Mode)

Write-Host "🚀 Создаем структуру Features..." -ForegroundColor Cyan

# 1. Удаляем временный placeholder
if (Test-Path "src/app/features/shell") {
    Remove-Item "src/app/features/shell" -Recurse -Force
    Write-Host "🗑️ Удален placeholder" -ForegroundColor Gray
}

# Функция для создания компонента
function New-NgComponent {
    param (
        [string]$Path,
        [string]$Name,
        [string]$Selector
    )

    $fullPath = "src/app/features/$Path"
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Force -Path $fullPath | Out-Null
    }

    # Используем Join-Path для правильных слешей
    $tsFile = Join-Path $fullPath "$Name.component.ts"
    $htmlFile = Join-Path $fullPath "$Name.component.html"
    
    # Генерация имени класса (kebab-case -> PascalCase)
    # Пример: verify-email -> VerifyEmailComponent
    $parts = $Name.Split('-')
    $classParts = foreach ($part in $parts) {
        $first = $part.Substring(0,1).ToUpper()
        $rest = $part.Substring(1)
        "$first$rest"
    }
    $className = ($classParts -join "") + "Component"

    # TS Content
    $tsContent = @"
import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: '$Selector',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './$Name.component.html',
})
export class $className {}
"@

    # HTML Content
    $htmlContent = "<h2>$className Works!</h2><p>TODO: Implement UI from pages.md</p>"

    Set-Content -Path $tsFile -Value $tsContent -Encoding UTF8
    Set-Content -Path $htmlFile -Value $htmlContent -Encoding UTF8
    
    Write-Host "✅ Created: $Path ($className)" -ForegroundColor Green
}

# 2. Создаем компоненты согласно docs/modules/iam/ui/routes.md

# --- AUTH ---
New-NgComponent -Path "auth/register" -Name "register" -Selector "app-register"
New-NgComponent -Path "auth/verify-email" -Name "verify-email" -Selector "app-verify-email"
New-NgComponent -Path "auth/forgot-password" -Name "forgot-password" -Selector "app-forgot-password"
New-NgComponent -Path "auth/invite" -Name "invite" -Selector "app-invite" 

# --- PROFILE ---
New-NgComponent -Path "profile/view" -Name "profile-view" -Selector "app-profile-view"
New-NgComponent -Path "profile/sessions" -Name "sessions" -Selector "app-sessions"

# --- ORGANIZATION ---
New-NgComponent -Path "organization/select" -Name "org-select" -Selector "app-org-select"
New-NgComponent -Path "organization/create" -Name "org-create" -Selector "app-org-create"

# --- ADMIN (RBAC) ---
New-NgComponent -Path "admin/users" -Name "admin-users" -Selector "app-admin-users"
New-NgComponent -Path "admin/roles" -Name "admin-roles" -Selector "app-admin-roles"
New-NgComponent -Path "admin/invites" -Name "admin-invites" -Selector "app-admin-invites"

Write-Host "🎉 Структура папок features создана!" -ForegroundColor Cyan