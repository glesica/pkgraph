FROM ubuntu:18.04

RUN apt-get update && apt-get install -y wget build-essential gnupg

# Dart
RUN apt-get install -y apt-transport-https
RUN wget -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
ADD dart_stable.list /etc/apt/sources.list.d/dart_stable.list

# Neo4j
RUN apt-get install -y openjdk-8-jre-headless
RUN wget -O - https://debian.neo4j.org/neotechnology.gpg.key | apt-key add -
ADD neo4j_stable.list /etc/apt/source.list.d/neo4j_stable.list

# Install Dependencies
RUN apt-get update && apt-get install -y dart neo4j

# Project Code
RUN mkdir /code
WORKDIR /code
ADD ../ .
RUN pub get

