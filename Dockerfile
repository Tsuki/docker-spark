FROM openjdk:8

MAINTAINER Alex Leung "alex.leung@nanfung.com"

# Scala related variables.
ARG SCALA_VERSION=2.12.2
ARG SCALA_BINARY_ARCHIVE_NAME=scala-${SCALA_VERSION}
ARG SCALA_BINARY_DOWNLOAD_URL=http://downloads.lightbend.com/scala/${SCALA_VERSION}/${SCALA_BINARY_ARCHIVE_NAME}.tgz

# SBT related variables.
ARG SBT_VERSION=0.13.15
ARG SBT_BINARY_ARCHIVE_NAME=sbt-$SBT_VERSION
ARG SBT_BINARY_DOWNLOAD_URL=https://dl.bintray.com/sbt/native-packages/sbt/${SBT_VERSION}/${SBT_BINARY_ARCHIVE_NAME}.tgz

# Spark related variables.
ARG SPARK_VERSION=2.2.1
ARG SPARK_BINARY_ARCHIVE_NAME=spark-${SPARK_VERSION}-bin-without-hadoop
ARG SPARK_BINARY_DOWNLOAD_URL=http://apache.website-solution.net/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-without-hadoop.tgz

ARG HADOOP_VERSION=3.0.0
ARG HADOOP_BINARY_ARCHIVE_NAME=hadoop-${HADOOP_VERSION}
ARG HADOOP_BINARY_DOWNLOAD_URL=http://apache.website-solution.net/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz


ARG LIVY_VERSION=0.5.0-incubating
ARG LIVY_BINARY_ARCHIVE_NAME=livy-${LIVY_VERSION}-bin
ARG LIVY_BINARY_DOWNLOAD_URL=http://apache.website-solution.net/incubator/livy/${LIVY_VERSION}/${LIVY_BINARY_ARCHIVE_NAME}.zip
# Configure env variables for Scala, SBT and Spark.
# Also configure PATH env variable to include binary folders of Java, Scala, SBT and Spark.
ENV SCALA_HOME      /usr/local/scala
ENV SBT_HOME        /usr/local/sbt
ENV SPARK_HOME      /usr/local/spark
ENV HADOOP_HOME     /usr/local/hadoop
ENV HADOOP_CONF_DIR /usr/local/hadoop/conf
ENV LIVY_HOME       /usr/local/livy
ENV PATH            $JAVA_HOME/bin:$SCALA_HOME/bin:$SBT_HOME/bin:$SPARK_HOME/bin:$SPARK_HOME/sbin:$HADOOP_HOME/bin:$LIVY_HOME/bin:$PATH

# Download, uncompress and move all the required packages and libraries to their corresponding directories in /usr/local/ folder.
RUN apt-get -yqq update && \
    apt-get install -yqq vim screen tmux bsdtar && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    cd /usr/local/ && \
    wget -qO - ${SCALA_BINARY_DOWNLOAD_URL} | tar -xz -C /usr/local/ && \
    wget -qO - ${SBT_BINARY_DOWNLOAD_URL} | tar -xz -C /usr/local/  && \
    wget -qO - ${SPARK_BINARY_DOWNLOAD_URL} | tar -xz -C /usr/local/ && \
    wget -qO - ${HADOOP_BINARY_DOWNLOAD_URL} | tar -xz -C /usr/local/ && \
    wget ${LIVY_BINARY_DOWNLOAD_URL} && unzip ${LIVY_BINARY_ARCHIVE_NAME}.zip && \
    ln -s ${SCALA_BINARY_ARCHIVE_NAME} scala && \
    ln -s ${SPARK_BINARY_ARCHIVE_NAME} spark && \
    ln -s ${HADOOP_BINARY_ARCHIVE_NAME} hadoop && \
    ln -s ${LIVY_BINARY_ARCHIVE_NAME} livy && \
    mkdir -p livy/logs && \
    cp spark/conf/log4j.properties.template spark/conf/log4j.properties && \
    sed -i -e s/WARN/ERROR/g spark/conf/log4j.properties && \
    sed -i -e s/INFO/ERROR/g spark/conf/log4j.properties



ADD core-site.xml /usr/local/hadoop/etc/hadoop
ENV HADOOP_CLASSPATH=/usr/local/hadoop/share/hadoop/tools/lib/*
ENV SPARK_DIST_CLASSPATH=/usr/local/hadoop/etc/hadoop:/usr/local/hadoop/share/hadoop/common/lib/*:/usr/local/hadoop/share/hadoop/common/*:/usr/local/hadoop/share/hadoop/hdfs:/usr/local/hadoop/share/hadoop/hdfs/lib/*:/usr/local/hadoop/share/hadoop/hdfs/*:/usr/local/hadoop/share/hadoop/mapreduce/*:/usr/local/hadoop/share/hadoop/yarn:/usr/local/hadoop/share/hadoop/yarn/lib/*:/usr/local/hadoop/share/hadoop/yarn/*:/usr/local/hadoop/share/hadoop/tools/lib/aliyun-sdk-oss-2.8.3.jar:/usr/local/hadoop/share/hadoop/tools/lib/aws-java-sdk-bundle-1.11.199.jar:/usr/local/hadoop/share/hadoop/tools/lib/azure-data-lake-store-sdk-2.2.3.jar:/usr/local/hadoop/share/hadoop/tools/lib/azure-keyvault-core-0.8.0.jar:/usr/local/hadoop/share/hadoop/tools/lib/azure-storage-5.4.0.jar:/usr/local/hadoop/share/hadoop/tools/lib/hadoop-aliyun-3.0.0.jar:/usr/local/hadoop/share/hadoop/tools/lib/hadoop-archive-logs-3.0.0.jar:/usr/local/hadoop/share/hadoop/tools/lib/hadoop-archives-3.0.0.jar:/usr/local/hadoop/share/hadoop/tools/lib/hadoop-aws-3.0.0.jar:/usr/local/hadoop/share/hadoop/tools/lib/hadoop-azure-3.0.0.jar:/usr/local/hadoop/share/hadoop/tools/lib/hadoop-azure-datalake-3.0.0.jar:/usr/local/hadoop/share/hadoop/tools/lib/hadoop-datajoin-3.0.0.jar:/usr/local/hadoop/share/hadoop/tools/lib/hadoop-distcp-3.0.0.jar:/usr/local/hadoop/share/hadoop/tools/lib/hadoop-extras-3.0.0.jar:/usr/local/hadoop/share/hadoop/tools/lib/hadoop-gridmix-3.0.0.jar:/usr/local/hadoop/share/hadoop/tools/lib/hadoop-kafka-3.0.0.jar:/usr/local/hadoop/share/hadoop/tools/lib/hadoop-openstack-3.0.0.jar:/usr/local/hadoop/share/hadoop/tools/lib/hadoop-resourceestimator-3.0.0.jar:/usr/local/hadoop/share/hadoop/tools/lib/hadoop-rumen-3.0.0.jar:/usr/local/hadoop/share/hadoop/tools/lib/hadoop-sls-3.0.0.jar:/usr/local/hadoop/share/hadoop/tools/lib/hadoop-streaming-3.0.0.jar:/usr/local/hadoop/share/hadoop/tools/lib/jdom-1.1.jar:/usr/local/hadoop/share/hadoop/tools/lib/kafka-clients-0.8.2.1.jar:/usr/local/hadoop/share/hadoop/tools/lib/lz4-1.2.0.jar:/usr/local/hadoop/share/hadoop/tools/lib/ojalgo-43.0.jar

# We will be running our Spark jobs as `root` user.
USER root

# Working directory is set to the home folder of `root` user.
WORKDIR /root

# Expose ports for monitoring.
# SparkContext web UI on 4040 -- only available for the duration of the application.
# Spark master’s web UI on 8080.
# Spark worker web UI on 8081.
EXPOSE 4040 8080 8081 8998

CMD ["/bin/bash"]
