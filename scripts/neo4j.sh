#!/bin/sh

mkdir -p data
docker run \
    --publish=7474:7474 --publish=7687:7687 \
    --env=NEO4J_AUTH=none \
    --detach \
    neo4j:3.5
