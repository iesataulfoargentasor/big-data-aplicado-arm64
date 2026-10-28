#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
dc=(docker compose -f docker-compose.kafka.yml)
topic="prueba-arm64-$(date +%s)-$$"
mensaje="mensaje-arm64-$topic"
for servicio in kafka-1 kafka-2 kafka-3 kafka-ui; do
  cid=$("${dc[@]}" ps -q "$servicio")
  [ -n "$cid" ] || { echo "No está activo $servicio"; exit 1; }
  imagen=$(docker inspect "$cid" --format '{{.Image}}')
  [ "$(docker image inspect "$imagen" --format '{{.Architecture}}')" = arm64 ] || exit 1
  echo "ARM64: $servicio"
done
"${dc[@]}" exec -T kafka-1 /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka-1:19092 --create --topic "$topic" --partitions 1 --replication-factor 3
printf '%s\n' "$mensaje" | "${dc[@]}" exec -T kafka-1 /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server kafka-1:19092 --topic "$topic" --command-property acks=all --command-property delivery.timeout.ms=30000 --command-property request.timeout.ms=10000
recibido=$("${dc[@]}" exec -T kafka-2 /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka-2:19092 --topic "$topic" --from-beginning --max-messages 1 --timeout-ms 30000 | tr -d '\r')
[ "$recibido" = "$mensaje" ] || { echo "Mensaje incorrecto: $recibido"; exit 1; }
sincronizado=false
for intento in $(seq 1 30); do
  descripcion=$("${dc[@]}" exec -T kafka-3 /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka-3:19092 --describe --topic "$topic")
  if grep -Eq 'Isr:[[:space:]]*[0-9]+,[0-9]+,[0-9]+([[:space:]]|$)' <<< "$descripcion"; then
    sincronizado=true; break
  fi
  sleep 2
done
[ "$sincronizado" = true ] || { echo 'No hay tres réplicas sincronizadas'; exit 1; }
echo "$descripcion"
echo "Kafka: producción y consumo OK. Se conserva el topic de prueba $topic."
