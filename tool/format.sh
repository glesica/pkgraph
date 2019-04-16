#!/bin/sh

set -e

dartfmt -l 80 -w --set-exit-if-changed lib/ test/ bin/

