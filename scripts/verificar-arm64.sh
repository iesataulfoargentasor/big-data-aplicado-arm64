#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
perfil=${1:-lake}
while IFS= read -r imagen; do
  arquitectura=$(docker image inspect "$imagen" --format '{{.Architecture}}')
  [ "$arquitectura" = arm64 ] || { echo "ERROR: $imagen = $arquitectura"; exit 1; }
  echo "ARM64: $imagen"
done < <(docker compose --profile "$perfil" config --images | sort -u)
for servicio in namenode resourcemanager dnnm hive-metastore hiveserver2; do
  if docker compose --profile "*" ps --status running --services | grep -qx "$servicio"; then
    propiedades=$(docker compose exec -T "$servicio" java -XshowSettings:properties -version 2>&1)
    grep -q 'os.arch = aarch64' <<< "$propiedades" || { echo "ERROR JVM: $servicio"; exit 1; }
    echo "JVM aarch64: $servicio"
  fi
done
