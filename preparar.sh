#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
perfil=${1:-lake}
case "$perfil" in lake|elt|hadoop|minio|hive|trino|lab|airflow|kafka) ;; *) echo "Uso: bash preparar.sh lake|elt|hadoop|minio|hive|trino|lab|airflow|kafka"; exit 2 ;; esac
if [ "$(uname -s)" != Darwin ] || [ "$(uname -m)" != arm64 ]; then
  echo "Ejecuta este asistente en macOS con Apple Silicon."; exit 1
fi
docker info >/dev/null
if [ ! -f .env ]; then
  sed "s/^AIRFLOW_UID=.*/AIRFLOW_UID=$(id -u)/" .env.example > .env
fi
if [ "$perfil" = kafka ]; then
  docker compose -f docker-compose.kafka.yml config -q
  docker compose -f docker-compose.kafka.yml pull
  echo "Preparado: docker compose -f docker-compose.kafka.yml up -d --wait"
  exit 0
fi
docker compose --profile "$perfil" config -q
case "$perfil" in
  lake|hadoop|hive|trino)
    docker build --platform linux/arm64 --build-arg LOCAL_UID="$(id -u)" -t bigdata-arm64-hadoop-base:3.3.6 Base
    ;;
esac
docker compose --profile "$perfil" build
docker compose --profile "$perfil" pull --ignore-buildable
while IFS= read -r imagen; do
  arquitectura=$(docker image inspect "$imagen" --format '{{.Architecture}}')
  if [ "$arquitectura" != arm64 ]; then
    echo "ERROR: $imagen tiene arquitectura $arquitectura"; exit 1
  fi
done < <(docker compose --profile "$perfil" config --images | sort -u)
echo "Imágenes ARM64 preparadas. Arranca con: bash iniciar.sh $perfil"
