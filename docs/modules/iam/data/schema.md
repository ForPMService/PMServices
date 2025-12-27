# IAM Database Schema

## Таблицы

### users
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | PK |
| keycloak_id | UUID | FK to Keycloak |
| email | VARCHAR(255) | Unique |
| first_name | VARCHAR(100) | |
| last_name | VARCHAR(100) | |
| avatar_url | TEXT | Nullable |
| email_verified | BOOLEAN | Default false |
| suspended | BOOLEAN | Default false |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

### organizations
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | PK |
| name | VARCHAR(255) | |
| slug | VARCHAR(100) | Unique |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

### memberships
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | PK |
| user_id | UUID | FK users |
| organization_id | UUID | FK organizations |
| created_at | TIMESTAMPTZ | |

### roles
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | PK |
| organization_id | UUID | FK organizations |
| name | VARCHAR(100) | |
| permissions | JSONB | Array of strings |
| is_system | BOOLEAN | Owner/Admin/Member |

### user_roles
| Column | Type | Description |
|--------|------|-------------|
| user_id | UUID | FK users |
| role_id | UUID | FK roles |
| organization_id | UUID | FK organizations |

### invites
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | PK |
| token | VARCHAR(64) | Unique |
| email | VARCHAR(255) | |
| organization_id | UUID | FK organizations |
| role_id | UUID | FK roles |
| expires_at | TIMESTAMPTZ | |
| accepted_at | TIMESTAMPTZ | Nullable |

## ER Диаграмма

TODO: Добавить PlantUML в `_assets/diagrams/iam-er.puml`
