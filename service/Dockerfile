FROM neo4j:3.5

ADD data.dump /data.dump

WORKDIR $NEO4J_HOME
RUN bin/neo4j-admin load --from /data.dump --database=graph.db --force
RUN echo "dbms.read_only=true" >> "conf/neo4j.conf"

ENV NEO4J_AUTH=none

