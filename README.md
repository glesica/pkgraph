# pkgraph

This is a WIP. Eventually it will be able to query a pub server and load the
resulting package dependency graph into a Neo4j database.

Stay tuned.

## Example Queries

Once you have some data loaded into a Neo4j database, what can you do with it?
There are some examples that might be useful or inspirational.

```cypher
match (:Source {url: "https://pub.dartlang.org"})<-[:HOSTED_ON]-
      (:Package {name: "state_machine"})-[:HAS_VERSION]->
      (state_machine:Version)-[:MAY_USE]->
      (w_common:Version)<-[:HAS_VERSION]-
      (:Package {name: "w_common"})
return state_machine.version as state_machine,
       collect(w_common.version) as w_common
```

This query will display a table of each available version of the `state_machine`
that depends on the `w_common` package along with the possible versions of the
`w_common` package that it can use.

## Known Issues

There's a bug around the `MAY_USE` relationship type. They are being inserted
kind of nonsensically.
