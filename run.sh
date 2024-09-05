#!/bin/bash

for run in $(seq 1 1); do
#	mpiexec -n 4 ./bin/main
	mpiexec -n 4 ./bin/moea
done
