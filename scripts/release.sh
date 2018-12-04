#!/usr/bin/env bash

# A simple script to verify that we've done all the things before publishing a
# new package version to the pub server.

set -e

version="$1"
if [[ -z "$version" ]]; then
    echo "usage: ./scripts/release.sh <version>"
    exit 1
fi

echo "Verify build"
pub get 2>&1 > /dev/null
pub run build_runner build 2>&1 > /dev/null
[ "$(git status -s)" == "" ]

echo "Verify pubspec.yaml"
grep -q -e "^version: $version" pubspec.yaml

echo "Verify CHANGELOG.md"
grep -q -e "^## $version" CHANGELOG.md

echo "Verify git tag"
git tag --contains | grep -q "$version"

echo "Ready to publish"
