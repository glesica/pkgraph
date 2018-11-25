#!/bin/sh

set -e

dartfmt -l 80 -w --set-exit-if-changed lib/ test/
dartanalyzer --fatal-infos --fatal-warnings lib/ test/
pub run test -r expanded
