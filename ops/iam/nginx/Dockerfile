FROM nginx:1.28-alpine

# Создаём директорию кеша с правильными правами — один раз при сборке образа,
# а не через shell-хак в compose command.
# При использовании named volume эта директория будет создана в volume при первом старте.
RUN mkdir -p /var/cache/nginx/kc \
    && chown -R nginx:nginx /var/cache/nginx

# Если примонтирован named volume в /var/cache/nginx/kc, то ownership будет root:root.
# Скрипты из /docker-entrypoint.d выполняются entrypoint'ом образа nginx при старте контейнера.
COPY 10-fix-cache-perms.sh /docker-entrypoint.d/10-fix-cache-perms.sh
RUN chmod +x /docker-entrypoint.d/10-fix-cache-perms.sh

# Security headers snippet — единый источник правды.
# Вынесено из default.conf чтобы избежать дублирования в каждом location.
RUN mkdir -p /etc/nginx/snippets
COPY snippets/security_headers.conf /etc/nginx/snippets/security_headers.conf

# Копируем конфиг — при локальной разработке можно перемонтировать через volume
COPY default.conf /etc/nginx/conf.d/default.conf
