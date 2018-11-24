# pkgraph

This is a WIP. Eventually it will be able to query a pub server and
load the resulting package dependency graph into a Neo4j database.

Stay tuned.

## Running

To run, just give it a package name and let it churn for awhile.

Note that right now you'll need to have Neo4j running on `localhost`,
and it will need to have authentication turned off. There is a script
in the `scripts/` directory that will run Neo4j, appropriately
configured, in a Docker container.

```shell
pub run pkgraph w_common
```

It is also possible to start your traversal at a local package or
application that may not be published to a pub server. Just pass
the `--local` flag and any package names you pass will be interpreted
as local paths to directories that contain `pubspec.yaml` files,
presumably Dart packages.

```shell
pub run pkgraph --local projects/secret_dart_app
```

## Example Queries

Once you have some data loaded into a Neo4j database, what can you do
with it? There are some examples that might be useful or inspirational.

```cypher
match (:Package {name: "w_common"})
      -[:HAS_VERSION]->(:Version)-[:MAY_USE]->(:Version)<-[:HAS_VERSION]-
      (d:Package)
return distinct d.name
```

The query above will find all packages that are depended upon by at
least one version of the `w_common` package.

```cypher
match (:Source {url: "https://pub.dartlang.org"})<-[:HOSTED_ON]-
      (:Package {name: "state_machine"})-[:HAS_VERSION]->
      (state_machine:Version)-[:MAY_USE]->
      (w_common:Version)<-[:HAS_VERSION]-
      (:Package {name: "w_common"})
return state_machine.version as state_machine,
       collect(w_common.version) as w_common
```

This query will display a table of each available version of the
`state_machine` that depends on the `w_common` package along with the
possible versions of the `w_common` package that it can use.

```cypher
match (p:Package)-[:HAS_VERSION]-(v:Version)
where v.dart2 = true
return p.name as package, collect(v.version) as versions
order by p.name asc
```

Dart 2 is out, have you heard? This query returns all the packages
that support Dart 2 and a list of specific versions that for each.

## Known Issues

In theory, the queries the tool runs should be idempotent, and should
just update nodes with new data. This means you should be able to run
it against an already-populated database without any trouble. However,
I haven't verified this and there are no tests for it, so it is
probably safer to blow away your database before re-running.

## Future Work

In addition to the work items listed below, there are, let's say ample,
additional items sprinkled throughout the source code.

1. Handle git dependencies
2. Parse author strings when possible to separate the name and email
3. Allow a combination of local, pub, and even git packages
4. Serialize the package version cache for reuse on subsequent runs
5. Allow custom Neo4j host and port
6. Include dev dependencies

Feel free to report issues if you find bugs or have suggestions to
improve the tool.
