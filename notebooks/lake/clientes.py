"""Clientes del laboratorio local. Las conexiones se cierran tras cada consulta."""
import re
import subprocess
import pandas as pd
from configuracion import ALUMNO

if not re.fullmatch(r"[a-z][a-z0-9_]{0,24}", ALUMNO):
    raise ValueError("ALUMNO: letra minúscula inicial; solo letras, números y guion bajo; máximo 25 caracteres")
BASE = f"/user/hdadmin/bda/{ALUMNO}"
DB = f"bda_{ALUMNO}"

def hdfs(*args):
    result = subprocess.run(["hdfs", "dfs", *args], check=True, text=True, capture_output=True)
    print(result.stdout)
    return result.stdout

def hive_sql(sql):
    from pyhive import hive
    con = hive.Connection(host="hiveserver2", port=10000, username="hdadmin", auth="NONE")
    try:
        cur = con.cursor()
        try:
            cur.execute(sql)
            if cur.description:
                return pd.DataFrame(cur.fetchall(), columns=[c[0] for c in cur.description])
        finally:
            cur.close()
    finally:
        con.close()

def trino_sql(sql):
    from trino.dbapi import connect
    con = connect(host="trino", port=8080, user="hdadmin", catalog="hive", schema=DB)
    try:
        cur = con.cursor()
        try:
            cur.execute(sql)
            filas = cur.fetchall()  # Agota también CREATE TABLE AS SELECT.
            if cur.description:
                return pd.DataFrame(filas, columns=[c[0] for c in cur.description])
            return pd.DataFrame()
        finally:
            cur.close()
    finally:
        con.close()

def minio():
    import boto3
    from botocore.config import Config
    return boto3.client("s3", endpoint_url="http://minio:9000",
        aws_access_key_id="minioadmin", aws_secret_access_key="minioadmin",
        region_name="us-east-1", config=Config(s3={"addressing_style": "path"}))
