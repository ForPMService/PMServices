import { Routes } from '@angular/router';

export const routes: Routes = [
  // --- Public Routes ---
  {
    path: 'auth',
    children: [
      {
        path: 'register',
        loadComponent: () => import('./features/auth/register/register.component').then(m => m.RegisterComponent)
      },
      {
        path: 'verify-email',
        loadComponent: () => import('./features/auth/verify-email/verify-email.component').then(m => m.VerifyEmailComponent)
      },
      {
        path: 'forgot-password',
        loadComponent: () => import('./features/auth/forgot-password/forgot-password.component').then(m => m.ForgotPasswordComponent)
      },
      {
        path: 'invite/:token',
        loadComponent: () => import('./features/auth/invite/invite.component').then(m => m.InviteComponent)
      },
      {
        path: 'login',
        // Для логина отдельный компонент не нужен, редиректим на главную (где сработает Guard или кнопка входа)
        redirectTo: '/',
        pathMatch: 'full'
      }
    ]
  },

  // --- Protected Routes (Profile) ---
  {
    path: 'profile',
    // Сюда позже добавим canActivate: [authGuard]
    children: [
      {
        path: '',
        loadComponent: () => import('./features/profile/view/profile-view.component').then(m => m.ProfileViewComponent)
      },
      {
        path: 'sessions',
        loadComponent: () => import('./features/profile/sessions/sessions.component').then(m => m.SessionsComponent)
      }
    ]
  },

  // --- Protected Routes (Organization) ---
  {
    path: 'select-organization',
    loadComponent: () => import('./features/organization/select/org-select.component').then(m => m.OrgSelectComponent)
  },
  {
    path: 'create-organization',
    loadComponent: () => import('./features/organization/create/org-create.component').then(m => m.OrgCreateComponent)
  },

  // --- Admin Routes ---
  {
    path: 'admin',
    children: [
      {
        path: 'users',
        loadComponent: () => import('./features/admin/users/admin-users.component').then(m => m.AdminUsersComponent)
      },
      {
        path: 'roles',
        loadComponent: () => import('./features/admin/roles/admin-roles.component').then(m => m.AdminRolesComponent)
      },
      {
        path: 'invites',
        loadComponent: () => import('./features/admin/invites/admin-invites.component').then(m => m.AdminInvitesComponent)
      }
    ]
  },

  // --- Default ---
  { path: '', redirectTo: 'profile', pathMatch: 'full' },
  { path: '**', redirectTo: 'profile' },
];