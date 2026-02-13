#!/bin/sh
# ═══════════════════════════════════════════════════════════════
# Kibana init — ждём готовности, импортируем saved objects
# ═══════════════════════════════════════════════════════════════

set -e

KIBANA_URL="http://kibana:5601"
MAX_RETRIES=60
RETRY_INTERVAL=5

echo "Waiting for Kibana at ${KIBANA_URL}..."
for i in $(seq 1 $MAX_RETRIES); do
    if curl -sf "${KIBANA_URL}/api/status" > /dev/null 2>&1; then
        echo "Kibana is ready (attempt ${i})"
        break
    fi
    if [ "$i" = "$MAX_RETRIES" ]; then
        echo "ERROR: Kibana not ready after ${MAX_RETRIES} attempts"
        exit 1
    fi
    sleep $RETRY_INTERVAL
done

# Импорт saved objects (data views)
echo "Importing saved objects..."
curl -sf -X POST "${KIBANA_URL}/api/saved_objects/_import?overwrite=true" \
    -H "kbn-xsrf: true" \
    -F file=@/tmp/saved-objects.ndjson

echo ""
echo "Kibana init complete"
