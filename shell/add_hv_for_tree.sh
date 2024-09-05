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
for pro in ${PRO}; do
for obj in ${OBJ}; do 			
for var in ${VAR}; do
#
for run in $(seq 1 $RUN); do
for alg in ${ALG}; do
	root="./tmp/OUTPUT"		
	h1=$root/$pro
	h2=$h1/OBJ$(printf '%02d' $obj)
	h3=$h2/VAR$(printf '%05d' $var)
	h4=$h3/$alg
	h5=$h4/obj
	h6=$h5/RUN$(printf '%03d' $run)

#	all of PF
#	if [  -d $h6 ]; then
#		cp $h6/* ./output
#	fi	

#	only last PF
	if [  -d $h6 ]; then
		num=$(ls $h6/* | wc -l )
		if [ $num -gt 1 ]; then
			cp $( ls $h6/* | tail -n 1 ) ./output

		fi
	fi	
#
done
done
	./shell/hv.sh
	rm -f ./output/*_obj_*
	./shell/tree_of_output_mv_2.0.sh
done
done
done
