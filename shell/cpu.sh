#!/bin/bash

rm -f ./bin/cpu_profiler && make
echo "1. compile is complete."

./bin/cpu_profiler
echo "2. runing is complete."

pprof --pdf ./bin/cpu_profiler ./profile/main.prof > cpu.pdf
echo "3. profiling is complete."
