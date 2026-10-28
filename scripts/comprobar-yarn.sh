#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Usa el cliente ARM64 de inicialización, sin arrancar Jupyter.
docker compose run --rm --no-deps hdfs-init hadoop jar /opt/bd/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar pi 1 1000
echo "MapReduce sobre YARN: OK"
