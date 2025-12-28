import { PassedInitialConfig, LogLevel } from 'angular-auth-oidc-client';

export const authConfig: PassedInitialConfig = {
  config: {
    // Адрес Keycloak (из вашего Docker setup)
    authority: 'http://localhost:8085/realms/pmservices',
    
    // Куда возвращаться после логина (наш локальный хост)
    redirectUrl: window.location.origin,
    postLogoutRedirectUri: window.location.origin,
    
    // ID клиента, который вы создали в Keycloak (Фаза 0)
    clientId: 'pmservices-spa',
    
    // Запрашиваем стандартные скоупы + offline_access для refresh token
    scope: 'openid profile email offline_access',
    
    responseType: 'code',
    silentRenew: true,
    useRefreshToken: true,
    renewTimeBeforeTokenExpiresInSeconds: 30,
    
    // Включаем логи, чтобы видеть в консоли, что происходит
    logLevel: LogLevel.Warn, 
    
    // Безопасные маршруты: к запросам на этот URL будет автоматически добавляться токен
    secureRoutes: ['/api/'], 
    
    customParamsAuthRequest: {
      prompt: 'login', 
    },
  },
};
