#!/bin/bash

# input: PRO, OBJ, VAR, ALG, RUN
source ./Args_for_shell.sh

# The direcotor output must be empty
n=$(ls output | wc -l)
if [ $n -ge 1 ]; then
	echo "output is not empty, exiting..."
	exit
fi

#
for run in $(seq 1 $RUN); do
for pro in ${PRO}; do
for obj in ${OBJ}; do 			
for var in ${VAR}; do
for alg in ${ALG}; do
	root="./tmp/OUTPUT"		
	h1=$root/$pro
	h2=$h1/OBJ$(printf '%02d' $obj)
	h3=$h2/VAR$(printf '%05d' $var)
	h4=$h3/$alg
	h5=$h4/obj
	h6=$h5/RUN$(printf '%03d' $run)

	if [  -d $h6 ]; then
		cp $h6/* ./output
		./shell/igd.sh
		rm -f ./output/*_obj_*
		./shell/tree_of_output_mv_2.0.sh
	fi	
done
done
done
done
done

