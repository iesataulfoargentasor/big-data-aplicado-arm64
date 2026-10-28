#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
perfil=${1:-lake}
case "$perfil" in lake|elt|hadoop|minio|hive|trino|lab|airflow) ;; *) echo "Uso: bash iniciar.sh lake|elt|hadoop|minio|hive|trino|lab|airflow"; exit 2 ;; esac
docker compose --profile "$perfil" up -d --no-build --pull never --wait --wait-timeout 900
