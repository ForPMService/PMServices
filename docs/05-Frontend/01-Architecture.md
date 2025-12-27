# Frontend Architecture

## Структура

```
pmservices-web/src/app/
├── core/              # Singletons (auth, http)
├── shared/            # UI Kit (после дизайна)
└── features/          # Feature modules
    ├── iam/
    └── projects/
```

## Feature Module

```
features/iam/
├── iam.routes.ts
├── api/               # API сервисы
├── pages/             # Page components
└── components/        # Feature-specific components
```

## Routing

- Lazy loading для каждого feature
- Guards для защиты роутов
