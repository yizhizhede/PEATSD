#!/bin/bash

rm -f ./bin/profiler
make profiler
./bin/profiler
# pprof ./bin/profiler ./bin/main.prof --pdf > ./bin/main.pdf
