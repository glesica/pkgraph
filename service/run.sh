#!/bin/sh

docker run \
    --detach \
    --publish=7474:7474 \
    --publish=7687:7687 \
    pkgraph

