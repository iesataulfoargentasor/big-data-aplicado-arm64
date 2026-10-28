"""Contrasta la copia DuckDB y los dos marts con los datos MySQL de origen."""
import json
import os
import platform
from decimal import Decimal
import duckdb
from sqlalchemy import create_engine, text

assert platform.machine() == 'aarch64', platform.machine()
engine = create_engine(os.environ['RETAIL_MYSQL_URL'])
db = duckdb.connect(os.environ['RETAIL_DUCKDB_PATH'], read_only=True)
tables = ['departments', 'categories', 'products', 'customers', 'orders', 'order_items']
counts = {}
with engine.connect() as mysql:
    for table in tables:
        source = mysql.execute(text(f'SELECT COUNT(*) FROM {table}')).scalar_one()
        target = db.execute(f'SELECT COUNT(*) FROM retail_raw.{table}').fetchone()[0]
        assert source == target and source > 0, (table, source, target)
        counts[table] = target
    total = mysql.execute(text("SELECT SUM(i.order_item_subtotal) FROM order_items i JOIN orders o ON i.order_item_order_id=o.order_id WHERE o.order_status IN ('COMPLETE','CLOSED')")).scalar_one()
money = lambda value: Decimal(str(value)).quantize(Decimal('0.01'))
totals = {}
for mart in ['ventas_por_ciudad', 'ventas_por_departamento']:
    value = db.execute(f'SELECT SUM(importe_total) FROM main_marts.{mart}').fetchone()[0]
    assert money(value) == money(total), (mart, value, total)
    totals[mart] = str(money(value))
db.close()
engine.dispose()
print(json.dumps({'resultado':'OK', 'arquitectura':platform.machine(), 'duckdb':duckdb.__version__, 'filas':counts, 'totales':totals}, ensure_ascii=False))
