import { provideAppInitializer } from '@angular/core';
import Keycloak from 'keycloak-js';
import { environment } from '../../../environments/environment';

export const keycloak = new Keycloak({
  url: environment.authUrl,
  realm: environment.keycloakRealm,
  clientId: environment.keycloakClientId,
});

async function initKeycloak(): Promise<void> {
  try {
    const ok = await keycloak.init({
      onLoad: 'check-sso',
      pkceMethod: 'S256',
      checkLoginIframe: false,
      silentCheckSsoRedirectUri: `${window.location.origin}/assets/silent-check-sso.html`,
    });

    console.info('[Keycloak] init ok:', ok);
  } catch (e) {
    console.error('[Keycloak] init failed:', e);
    // не бросаем ошибку — приложение поднимается даже без Keycloak
  }
}

export const KEYCLOAK_PROVIDERS = [
  provideAppInitializer(() => initKeycloak()),
];

