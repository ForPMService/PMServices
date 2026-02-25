#!/usr/bin/env sh
set -eu

# IMPORTANT:
# When a Docker named volume is mounted into /var/cache/nginx/kc,
# it is created with root ownership. NGINX workers (user: nginx)
# then cannot write proxy cache files, and caching silently breaks.

mkdir -p /var/cache/nginx/kc
chown -R nginx:nginx /var/cache/nginx
