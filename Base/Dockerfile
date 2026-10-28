# Imagen base del clúster. No se ejecuta como servicio.
# La construye preparar.sh antes de construir los servicios.
# También se puede construir sola:
#   docker build -t bigdata-arm64-hadoop-base:3.3.6 .
FROM ubuntu:22.04
LABEL maintainer="Profesor <jose.martin@educantabria.es>"

USER root

# Hadoop 3.3.6 funciona con Java 8. Ubuntu 22.04 todavía publica openjdk-8.
# Distribución ARM64 oficial; suma SHA-512 verificada durante la construcción.
ENV HADOOP_VERSION=3.3.6
ENV HADOOP_HEAPSIZE_MAX=512
ENV HADOOP_COMMON_LIB_NATIVE_DIR=/opt/bd/hadoop/lib/native
ENV LD_LIBRARY_PATH=/opt/bd/hadoop/lib/native
ENV BASE_DIR=/opt/bd
ENV LOG_TAG="[BASE Hadoop_${HADOOP_VERSION}]:"
ARG REPOSITORY=https://downloads.apache.org/hadoop/core
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-arm64
ENV HADOOP_HOME=${BASE_DIR}/hadoop
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
ENV PATH=${PATH}:${JAVA_HOME}/bin:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin
ENV LANG=es_ES.UTF-8
ENV LC_ALL=es_ES.UTF-8

RUN echo "$LOG_TAG Actualizando e instalando paquetes básicos" && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        openjdk-8-jdk \
        libbcprov-java \
        python3 \
        python3-pip \
        curl \
        ca-certificates \
        locales \
        iputils-ping \
        procps \
        nano file libsnappy1v5 libzstd1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN echo "$LOG_TAG Creando locales" && \
    sed -i '/es_ES.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen es_ES.UTF-8 && \
    update-locale LANG=es_ES.UTF-8

RUN mkdir -p ${BASE_DIR}
WORKDIR ${BASE_DIR}

RUN echo "$LOG_TAG Descargando Hadoop" && \
    curl -fsSL --retry 3 --retry-delay 2 -o hadoop-${HADOOP_VERSION}-aarch64.tar.gz \
        "${REPOSITORY}/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}-aarch64.tar.gz" && \
    echo "b0a485c5ae0d97b08285bb83a3dd78b834153b2bd53f96ac301852862ccaff139f2c547aee808d5ad4afdc3a204b1c3b6ba459ea83ebf2779e9c129f37c69059  hadoop-${HADOOP_VERSION}-aarch64.tar.gz" | sha512sum -c - && \
    tar xzf hadoop-${HADOOP_VERSION}-aarch64.tar.gz && \
    ln -s hadoop-${HADOOP_VERSION} hadoop && \
    rm hadoop-${HADOOP_VERSION}-aarch64.tar.gz && \
    echo "export JAVA_HOME=${JAVA_HOME}" >> ${HADOOP_CONF_DIR}/hadoop-env.sh && \
    echo "export HADOOP_HOME=${HADOOP_HOME}" >> ${HADOOP_CONF_DIR}/hadoop-env.sh

# hdadmin ejecuta los demonios y el cliente. El directorio temporal tiene que
# existir y ser suyo: core-site.xml apunta a /var/tmp/hadoop-${user.name}.
ARG LOCAL_UID=501
RUN groupadd -r hadoop && \
    useradd -u "${LOCAL_UID}" -g hadoop -d ${BASE_DIR} -s /bin/bash hdadmin && \
    mkdir -p /var/tmp/hadoop-hdadmin ${HADOOP_HOME}/logs && \
    chown hdadmin:hadoop /var/tmp/hadoop-hdadmin ${HADOOP_HOME}/logs ${HADOOP_CONF_DIR}/hadoop-env.sh
