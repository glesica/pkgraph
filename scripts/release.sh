#!/usr/bin/env bash

# A simple script to verify that we've done all the things before publishing a
# new package version to the pub server.

set -e

version="$1"
if [[ -z "$version" ]]; then
    echo "usage: ./scripts/release.sh <version>"
fi

echo "Verify pubspec.yaml"
grep -q "version: $version" pubspec.yaml

echo "Verify CHANGELOG.md"
grep -q "## $version" CHANGELOG.md

echo "Verify git tag"
git tag --contains | grep -q "$version"

echo "Ready to publish"

