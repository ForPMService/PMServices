import { ApplicationConfig, provideZoneChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { provideAuth, authInterceptor } from 'angular-auth-oidc-client';

import { routes } from './app.routes';
import { authConfig } from './core/auth/auth.config';

export const appConfig: ApplicationConfig = {
  providers: [
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes),
    
    // Подключаем HttpClient и Интерсептор (он сам добавит Bearer token к запросам)
    provideHttpClient(withInterceptors([authInterceptor()])),

    // Инициализируем OIDC
    provideAuth(authConfig),
  ],
};
