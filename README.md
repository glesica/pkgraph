# pkgraph

This is a WIP. Eventually it will be able to query a pub server and load the
resulting package dependency graph into a Neo4j database.

Stay tuned.

## Known Issues

There's a bug around the `MAY_USE` relationship type. They are being inserted
kind of nonsensically.
