# Observability: ELK (Elastic + Kibana) — задел

## Зачем
ELK нужен, чтобы:
- видеть логи в одном месте
- фильтровать по correlationId/traceId (когда добавишь)
- находить ошибки по сервисам/модулям и по времени

## Как включать
В `ops/compose.yml` ELK подключён профилем `observability`.

Запуск:
```bash
cd ops
docker compose --profile observability up -d
```

Доступ:
- Elasticsearch: http://localhost:9200
- Kibana: http://localhost:5601

## Как будем интегрировать backend (план)
Вариант 1 (просто и надёжно):
- backend пишет structured-логи в stdout (JSON)
- отдельный агент (позже) читает контейнерные логи и отправляет в Elasticsearch

Вариант 2 (быстро для dev):
- direct sink из приложения (например через логгер) в Elasticsearch

Рекомендация для старта: **stdout + контейнерные логи**,
а direct sink включать только если очень нужно.

## Что сделать на этой неделе
- добавить health endpoint в API
- добавить correlationId (минимум: request-id) в логи
- договориться о полях в логе: service, module, userId(optional), traceId
