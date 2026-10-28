# Big Data Aplicado · ARM64

**[Guía web de despliegue](https://iesataulfoargentasor.github.io/big-data-aplicado-arm64/)** · **[Descargar ZIP](https://github.com/iesataulfoargentasor/big-data-aplicado-arm64/archive/refs/heads/main.zip)**


Adaptación del [stack docente del IES Ataúlfo Argenta](https://github.com/iesataulfoargentasor/bigdata-stack-mac-m4).
Hadoop 3.3.6 y Hive 4.0.1 se construyen ahora para ARM64, igual que los demás servicios. No necesitan Rosetta ni imágenes AMD64.

## Qué cambia

- Hadoop: Ubuntu ARM64, OpenJDK 8 ARM64 y distribución oficial hadoop-3.3.6-aarch64. La descarga se comprueba con SHA-512.
- Hive: imagen oficial apache/hive:4.0.1 ARM64 fijada por digest, con el conector MySQL y las bibliotecas Hadoop ARM64.
- Se conservan HDFS, YARN, Hive Metastore, HiveServer2, MinIO, Trino y MySQL, así como los perfiles ELT y Kafka del proyecto de origen.
- El proyecto se llama bigdata-arm64-m4 y utiliza volúmenes propios. Arranca con datos nuevos; no migra los del stack anterior.
- La JVM de los demonios de Hadoop tiene un máximo predeterminado de 512 MiB. Los trabajos YARN disponen de su propio presupuesto, configurado en los XML.

## Preparar el Mac

1. Abre Docker Desktop para Apple Silicon. Como orientación para clase, asigna 12 GB de RAM y 6 CPU. El resto queda para macOS y tus aplicaciones. Para trabajos mayores necesitarás ajustar recursos y volumen de datos.
2. Detén el stack anterior de Big Data y el de Spark antes de iniciar éste: conservamos sus puertos habituales.
3. Descomprime en una carpeta local fuera de iCloud Drive. Reserva espacio suficiente: la primera construcción descarga varios GB y conserva caché de construcción.
4. Abre Terminal en la carpeta que contiene compose.yaml.

No necesitas instalar Java, Hadoop, Hive o Python en macOS. Sí necesitas Internet para la primera preparación y Docker Compose reciente (2.20 o posterior).

## Lago: HDFS, Hive, MinIO, Trino y MySQL

```bash
bash preparar.sh lake
bash iniciar.sh lake
bash comprobar.sh lake
```

La preparación construye primero la base Hadoop y después los servicios que dependen de ella. Puede tardar varios minutos.
El asistente verifica que todas las imágenes del escenario sean ARM64. No ejecutes directamente los antiguos Dockerfiles como imágenes Intel.

La comprobación prueba arquitectura de imágenes y JVM, HDFS, consultas Hive con Tez, tablas Parquet y acceso desde Trino a HDFS, MinIO y MySQL.
Escribe exclusivamente tablas de demostración con los prefijos prueba_arm64 y prueba_m4. No debe utilizarse sobre datos de producción.

Hive ejecuta Tez en modo local dentro de HiveServer2, como el material de origen. Esto es distinto de enviar las consultas Hive a YARN.

Para probar también un trabajo MapReduce real sobre YARN:

```bash
bash scripts/comprobar-yarn.sh
```

Ejecuta una pequeña estimación de Pi mediante un cliente temporal. YARN debe mostrar la aplicación como FINISHED y SUCCEEDED.

## Interfaces

| Servicio | Dirección | Acceso |
|---|---|---|
| NameNode HDFS | http://localhost:9870 | Explorador de archivos y estado |
| ResourceManager YARN | http://localhost:8088 | Aplicaciones y recursos |
| NodeManager | http://localhost:8042 | Tareas del nodo |
| Trino | http://localhost:8080 | Consultas |
| HiveServer2 | http://localhost:10002 | Interfaz web |
| Hive JDBC | jdbc:hive2://localhost:10000/default | Usuario hdadmin |
| MinIO | http://localhost:9001 | minioadmin / minioadmin |
| MySQL metastore | localhost:3306 | hive / hive |
| MySQL retail | localhost:3307 | retail / retail |

Todos los puertos publicados se limitan a 127.0.0.1. Son credenciales docentes locales.

Ejemplo de consola Hive:

```bash
docker compose exec hiveserver2 beeline -u jdbc:hive2://localhost:10000/default -n hdadmin
```

## Cliente Hadoop con Jupyter

El perfil lake usa el cliente para inicialización y pruebas, pero no arranca su cuaderno permanentemente.
Para trabajar con el cliente y mantener el lago:

```bash
bash preparar.sh hadoop
docker compose --profile lake --profile hadoop up -d --no-build --pull never --wait --wait-timeout 900
```

Abre http://localhost:8889. La carpeta notebooks/ se comparte con el cliente.
preparar.sh usa tu UID de macOS al construir Hadoop para facilitar la escritura en esa carpeta.

## ELT y Airflow: validados en ARM64

Guarda tu trabajo y detén el escenario actual antes de cambiar:

```bash
bash parar.sh
bash preparar.sh elt
bash iniciar.sh elt
bash comprobar.sh elt
bash scripts/comprobar-airflow.sh
```

ELT conserva MySQL → dlt → DuckDB → dbt, Jupyter y Airflow. Jupyter está en http://localhost:8888 y Airflow en http://localhost:8082 (admin/admin).
No ejecutes simultáneamente el flujo manual y el DAG sobre el mismo archivo DuckDB. El comprobador de Airflow dispara una ejecución real, espera las tres tareas y contrasta los resultados con MySQL. Antes debes preparar y arrancar elt, como en el ejemplo.

## Kafka: validado en ARM64

Kafka utiliza su Compose independiente:

```bash
bash parar.sh
bash preparar.sh kafka
docker compose -f docker-compose.kafka.yml up -d --wait --wait-timeout 600
bash scripts/comprobar-kafka.sh
```

Su consola está en http://localhost:8083. Detén Kafka con docker compose -f docker-compose.kafka.yml stop.
El comprobador crea un topic de prueba, envía un mensaje con acks=all, lo consume desde otro broker y exige tres réplicas sincronizadas. Conserva ese topic para que puedas verlo en la consola.

Se han probado los tres escenarios por separado: lago, ELT/Airflow y Kafka. También se comprobó la continuidad de Kafka al detener el líder y la persistencia después de recrear contenedores. La consola Kafka UI está fijada al digest de la imagen ARM64 probada.

Consulta PRACTICAS.md para los ejercicios y VALIDACION.txt para el alcance y los resultados.

## Parar, reanudar y conservar datos

```bash
bash parar.sh
bash iniciar.sh lake
```

Los volúmenes de HDFS, MySQL y MinIO se conservan; los archivos de trabajo están en workspace/ y notebooks/.
No uses down -v si quieres conservar los datos: elimina los volúmenes.
No conectes esta variante directamente a los volúmenes del stack anterior sin una migración planificada.
El arranque utiliza las imágenes ya construidas y no requiere Internet, salvo que tus prácticas descarguen datos o paquetes externos.

## Diagnóstico

```bash
docker compose --profile '*' ps -a
docker compose logs --tail 100 namenode resourcemanager dnnm hive-metastore hiveserver2 trino
bash scripts/verificar-arm64.sh lake
```

Los inicializadores hdfs-init, minio-init y retail-init deben terminar con Exited (0): es normal.
La comprobación ARM64 debe mostrar imágenes arm64 y JVM aarch64. No es necesario activar Rosetta para este stack.
Pueden aparecer advertencias de Java, SLF4J o módulos Hadoop opcionales; no implican emulación AMD64.
Para interpretar un error consulta el registro del servicio y VALIDACION.txt.

Si falla la descarga de Hadoop porque Apache ha trasladado la versión, Base/Dockerfile admite --build-arg REPOSITORY=https://archive.apache.org/dist/hadoop/common. Se mantiene la misma suma SHA-512.

## Procedencia

Se mantienen las versiones y ejercicios del repositorio docente indicado arriba. Se han cambiado las imágenes Hadoop/Hive, rutas Java, construcción, nombre del proyecto y pruebas de aceptación.
No se han publicado cambios en GitHub.
Fuentes: [Hadoop 3.3.6 ARM64](https://downloads.apache.org/hadoop/core/hadoop-3.3.6/) y [Hive oficial](https://hub.docker.com/r/apache/hive).

## Guía visual

La guía de `docs/` explica cómo desplegar este laboratorio en MacBook Air M4 de 24 GB e incluye esquemas de sus servicios. Se publica con GitHub Pages desde `main` → `/docs`.
