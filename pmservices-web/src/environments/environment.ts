import type { Environment } from './environment.model';

export const environment = {
  production: true,
  apiBaseUrl: 'https://api.pmservices.com',

  authUrl: 'https://auth.pmservices.com',
  keycloakRealm: 'pmservices',
  keycloakClientId: 'pmservices-spa',
} satisfies Environment;