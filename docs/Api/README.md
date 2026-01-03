# PMServices IAM API - Документация

Красивая документация API в формате Swagger UI и ReDoc.

## 📁 Содержимое

- `index.html` - Swagger UI (интерактивная документация)
- `redoc.html` - ReDoc (современный, читаемый формат)
- `openapi.yaml` - OpenAPI 3.1 спецификация

## 🚀 Быстрый старт

### Локальный запуск

Просто откройте HTML файлы в браузере через любой локальный веб-сервер:

**Вариант 1: Python**
```bash
# Python 3
python -m http.server 8000

# Python 2
python -m SimpleHTTPServer 8000
```

**Вариант 2: Node.js (http-server)**
```bash
npx http-server -p 8000
```

**Вариант 3: VS Code**
Установите расширение "Live Server" и нажмите "Go Live"

Затем откройте:
- Swagger UI: http://localhost:8000/
- ReDoc: http://localhost:8000/redoc.html

## 🌐 Размещение на GitHub Pages

### Вариант 1: Через настройки репозитория

1. Создайте новый репозиторий на GitHub (например, `iam-api-docs`)

2. Загрузите файлы:
```bash
git init
git add .
git commit -m "Initial commit: API documentation"
git branch -M main
git remote add origin https://github.com/ваш-username/iam-api-docs.git
git push -u origin main
```

3. Включите GitHub Pages:
   - Перейдите в Settings → Pages
   - Source: Deploy from a branch
   - Branch: main, папка: / (root)
   - Нажмите Save

4. Через несколько минут документация будет доступна по адресу:
   `https://ваш-username.github.io/iam-api-docs/`

### Вариант 2: GitHub Actions (автоматическое развертывание)

Создайте файл `.github/workflows/deploy.yml`:

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Pages
        uses: actions/configure-pages@v4
      
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: '.'
      
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

## 📝 Доступные форматы документации

### Swagger UI (`index.html`)
**Преимущества:**
- ✅ Интерактивное тестирование API
- ✅ Возможность отправки запросов прямо из браузера
- ✅ Поддержка авторизации (OAuth2, Bearer)
- ✅ Привычный интерфейс для разработчиков

**Когда использовать:**
- Для тестирования и отладки API
- Для разработчиков, которые хотят попробовать endpoints

### ReDoc (`redoc.html`)
**Преимущества:**
- ✅ Современный, чистый дизайн
- ✅ Отличная читаемость
- ✅ Адаптивная вёрстка
- ✅ Быстрая навигация
- ✅ Идеально для публичной документации

**Когда использовать:**
- Для внешних разработчиков и партнёров
- Для презентации API
- Когда нужна красивая, профессиональная документация

## 🔧 Кастомизация

### Изменение темы Swagger UI

Отредактируйте `index.html`, раздел `<style>`:

```css
.topbar {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    /* Ваш цвет */
}
```

### Изменение темы ReDoc

В `redoc.html` найдите атрибут `theme` и измените цвета:

```javascript
"colors": {
    "primary": {"main": "#ВАШ_ЦВЕТ"}
}
```

## 📖 Структура OpenAPI файла

Ваш `openapi.yaml` включает:
- **14 групп endpoints** (Health, Registration, Session, Profile, Security, Auth, Organizations, Members, Invites, InviteLinks, RBAC, Audit, Internal)
- **Полное описание схем** данных
- **Примеры запросов** и ответов
- **Описание ошибок** (IAM-001 - IAM-021)
- **Security schemes** (OpenID Connect + Bearer)

## 🔐 Авторизация в Swagger UI

Для тестирования endpoints:

1. Нажмите кнопку **Authorize** в Swagger UI
2. Выберите схему:
   - `OpenIdConnectLocal` - для локальной разработки
   - `OpenIdConnectProd` - для production
   - `BearerAuth` - для ручного ввода токена
3. Пройдите авторизацию или вставьте токен

## 🛠 Обновление документации

1. Отредактируйте `openapi.yaml`
2. Зафиксируйте изменения:
```bash
git add openapi.yaml
git commit -m "Update API specification"
git push
```

GitHub Pages автоматически обновится через 1-2 минуты.

## 📊 Альтернативные платформы для хостинга документации

Если GitHub Pages не подходит:

1. **SwaggerHub** (https://swagger.io/tools/swaggerhub/)
   - Бесплатный план для публичной документации
   - Встроенный редактор
   - Автоматическая валидация

2. **Redocly** (https://redocly.com/)
   - Красивый дизайн из коробки
   - CDN для быстрой загрузки
   - Бесплатный план

3. **Stoplight** (https://stoplight.io/)
   - Визуальный редактор
   - Автоматическая генерация mock servers
   - Бесплатный план для публичных проектов

4. **GitBook** (https://www.gitbook.com/)
   - Для более комплексной документации
   - Интеграция с Git
   - Красивое оформление

## 🆘 Поддержка

Если возникли вопросы по настройке:
- Проверьте, что файлы находятся в корне репозитория
- Убедитесь, что GitHub Pages включён в настройках
- Проверьте, что branch выбран правильно (main)

## 📄 Лицензия

Proprietary - PMServices Team (dev@pmservices.io)

---

**Версия API:** 1.2.0  
**Контакт:** dev@pmservices.io  
**Сайт:** https://pmservices.io
