"""Salida 0: DAG y tres tareas OK; 2: pendiente; 1: error."""
import json
import platform
import sys
from airflow.models.dagrun import DagRun
from airflow.models.taskinstance import TaskInstance
from airflow.utils.session import create_session

assert platform.machine() == 'aarch64', platform.machine()
run_id = sys.argv[1]
expected = {'dlt_mysql_a_duckdb', 'dbt_run', 'dbt_test'}
with create_session() as session:
    run = session.query(DagRun).filter_by(dag_id='elt_retail', run_id=run_id).one_or_none()
    tasks = session.query(TaskInstance).filter_by(dag_id='elt_retail', run_id=run_id).all()
    states = {task.task_id: task.state for task in tasks}
    state = run.state if run else None
print(json.dumps({'run_id':run_id, 'estado':state, 'tareas':states, 'arquitectura':platform.machine()}))
if state == 'success':
    assert set(states) == expected and all(value == 'success' for value in states.values()), states
    sys.exit(0)
if state == 'failed' or any(value in ('failed','upstream_failed') for value in states.values()):
    sys.exit(1)
sys.exit(2)
