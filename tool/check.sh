#!/bin/sh

set -e

dartanalyzer --fatal-infos --fatal-warnings lib/ test/ bin/
pub run test

