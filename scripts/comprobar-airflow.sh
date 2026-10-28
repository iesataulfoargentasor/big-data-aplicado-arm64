#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo 'Cierra DuckDB y no ejecutes el flujo manual durante esta prueba.'
run_id="validacion_arm64_$(date +%s)_$$"
docker compose exec -T airflow-scheduler airflow dags unpause elt_retail
docker compose exec -T airflow-scheduler airflow dags trigger --run-id "$run_id" elt_retail
for intento in $(seq 1 120); do
  if docker compose exec -T airflow-scheduler python /workspace/init/estado_dag_validacion.py "$run_id"; then
    docker compose exec -T airflow-scheduler /opt/elt-venv/bin/python /workspace/init/verificar_elt.py
    echo 'Airflow: DAG, tres tareas y datos finales OK'
    exit 0
  else
    estado=$?
    if [ "$estado" -ne 2 ]; then
      echo "Falló el DAG $run_id; consulta sus registros en Airflow."; exit 1
    fi
  fi
  sleep 5
done
echo "Tiempo agotado esperando el DAG $run_id"; exit 1
