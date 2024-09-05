#!/bin/bash

rm -f ./bin/heap_profiler && make
echo "1. compile is complete."

rm -f ./profile/main.hprof.*
./bin/heap_profiler
echo "2. runing is complete."

i=1;
for file in profile/main.hprof.*; do
	pprof --pdf ./bin/heap_profiler $file > heap$(printf '%04d' $i).pdf
	i=$[ $i + 1 ]
done
echo "3. profiling is complete."
