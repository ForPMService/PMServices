# Architectural Decision Records

## Что такое ADR

ADR фиксирует важные архитектурные решения:
- Контекст (почему вопрос возник)
- Решение (что выбрали)
- Последствия (плюсы/минусы)

## Как создать ADR

1. Скопировать [0000-template.md](./0000-template.md)
2. Переименовать в `NNNN-short-title.md`
3. Заполнить секции
4. PR → Review → Merge
5. Обновить Status на `Accepted`

## Список ADR

| # | Решение | Статус |
|---|---------|--------|
| 0000 | [Template](./0000-template.md) | Template |
| 0001 | [Tenancy Model](./0001-tenancy-model.md) | Proposed |
| 0002 | [RBAC Placement](./0002-rbac-placement.md) | Proposed |
| 0003 | [Token Storage SPA](./0003-token-storage-spa.md) | Proposed |

## Когда создавать ADR

- Влияет на безопасность
- Сложно откатить
- Меняет границы модулей
- Новый технологический выбор
