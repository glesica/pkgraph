FROM ubuntu:18.04

# General
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
RUN apt-get update && apt-get install -y \
    apt-utils \
    gnupg \
    wget

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

# Neo4j
ENV NEO4J_AUTH=none
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

# Project Directory
RUN mkdir /code

