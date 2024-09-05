#!/bin/bash

# input: PRO, OBJ, VAR, ALG, RUN
source ./Args_for_shell.sh

for alg in ${ALG}; do
for pro in ${PRO}; do
for obj in ${OBJ}; do 			
for var in ${VAR}; do
for run in $(seq 1 ${RUN}); do
	root="./tmp/OUTPUT"		
	h1=$root/$pro
	h2=$h1/OBJ$(printf '%02d' $obj)
	h3=$h2/VAR$(printf '%05d' $var)
	h4=$h3/$alg
	h5=$h4/obj
	h6=$h5/RUN$(printf '%03d' $run)

	if [  -d $h6 ]; then
		echo "mv $h6/* ./output/"
		mv $h6/* ./output/
	fi	
done
done
done
done
done
