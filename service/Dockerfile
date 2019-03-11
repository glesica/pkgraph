FROM ubuntu:18.04

# General
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
RUN apt-get update && apt-get install -y \
    apt-utils \
    gnupg \
    wget

# Neo4j
RUN apt-get update && apt-get install -y \
    openjdk-8-jre-headless
RUN wget -O - https://debian.neo4j.org/neotechnology.gpg.key \
    | apt-key add -
ADD integration/neo4j_stable.list \
    /etc/apt/sources.list.d/neo4j_stable.list
RUN apt-get update && apt-get install -y \
    neo4j=1:3.5.0 \
    neo4j-client
RUN neo4j-admin set-initial-password password

# Dart
ENV PATH="/usr/lib/dart/bin:${HOME}/.pub-cache/bin:${PATH}"
RUN apt-get update && apt-get install -y \
    apt-transport-https
RUN wget -O - https://dl-ssl.google.com/linux/linux_signing_key.pub \
    | apt-key add -
ADD integration/dart_stable.list \
    /etc/apt/sources.list.d/dart_stable.list
RUN apt-get update && apt-get install -y \
    dart

# Pkgraph
RUN pub global activate pkgraph || true

# Run the ETL
RUN service neo4j start && \
    sleep 5 && \
    service neo4j status && \
    pub global run pkgraph \
        --neo4j-user=neo4j \
        --neo4j-pass=password \
        charcode && \
    sleep 5 && \
    service neo4j stop && \
    sleep 5

# Dump the database
#RUN neo4j-admin dump --database=graph.db --to=/var/lib/neo4j/pub.dump
#
## ------------
## Deploy stage
## ------------
#
#FROM neo4j:3.5
#WORKDIR $NEO4J_HOME
#COPY --from=etl /var/lib/neo4j/pub.dump pub.dump
#RUN bin/neo4j-admin load --from pub.dump --database=graph.db --force
#
## Configure the deploy Neo4j instance
#ENV NEO4J_AUTH=none
#ENV NEO4J_dbms_read__only=true
