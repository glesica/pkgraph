#!/bin/sh

service neo4j start
pub run pkgraph \
    --neo4j-user=neo4j \
    --neo4j-pass=password \
    pkgraph
neo4j-client \
    --insecure \
    --non-interactive \
    --username=neo4j \
    --password=password \
    --source smoke-test.cypher \
    --output smoke-test.log

