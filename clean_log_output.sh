#!/bin/bash

# get the number of CPU(s)
line=$(lscpu | sed -n '5p')
arr=($line)
CPUs=${arr[1]}

# 1. clear output
find output -name "*_var_*"  | xargs -n 100 -P ${CPUs} rm -f
find output -name "*_obj_*"  | xargs -n 100 -P ${CPUs} rm -f 
find output -name "*_igd_*"  | xargs -n 100 -P ${CPUs} rm -f 
find output -name "*_hv_*"   | xargs -n 100 -P ${CPUs} rm -f 
find output -name "*_ash_*"  | xargs -n 100 -P ${CPUs} rm -f 
find output -name "*_time_*" | xargs -n 100 -P ${CPUs} rm -f
find output -name "*_fitness_*" | xargs -n 100 -P ${CPUs} rm -f
find output -name "*_desire_*" | xargs -n 100 -P ${CPUs} rm -f
find output -name "*_grp_*" | xargs -n 100 -P ${CPUs} rm -f
rm -rf output/*

#
rm -f log/*
rm -f f*.png
rm -f heap*.pdf
rm -f cpu.pdf 
rm -f var-run*.png 
rm -f "nohup.out"
rm -f octave-workspace  
rm -f latex/*
rm -f profile/*
rm -rf tmp/*
rm -f list_of_parameters* 
