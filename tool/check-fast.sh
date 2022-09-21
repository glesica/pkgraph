#!/bin/sh

set -e

dart analyze --fatal-infos --fatal-warnings lib/ test/ bin/
dart test test/unit
