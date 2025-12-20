import type { Environment } from './environment.model';

export const environment = {
  production: false,
  apiBaseUrl: 'http://localhost:5000',

  authUrl: 'http://localhost:8085',
  keycloakRealm: 'pmservices',
  keycloakClientId: 'pmservices-spa',
} satisfies Environment;
