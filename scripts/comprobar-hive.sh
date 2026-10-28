#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose exec -T hiveserver2 beeline -u jdbc:hive2://localhost:10000/default -n hdadmin --silent=true -f /opt/prueba-hive.sql
resultado=$(docker compose exec -T hiveserver2 beeline -u jdbc:hive2://localhost:10000/default -n hdadmin --silent=true --showHeader=false --outputformat=tsv2 -e 'SELECT pais, SUM(importe) FROM prueba_arm64.ventas GROUP BY pais ORDER BY pais' | tr -d '\r')
if [ "$resultado" != $'ES\t30\nFR\t12' ]; then
  echo "ERROR: resultado Hive inesperado: $resultado"; exit 1
fi
echo "HiveServer2 + Tez + HDFS: OK (ES=30, FR=12)"
