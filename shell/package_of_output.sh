#!/bin/bash

for i in $(seq 1 20); do
	no=$(printf '%02d' ${i})
        find output -name "*_${no}_*"  | xargs -n 100 tar -rf output.${no}.tar &
done
wait
