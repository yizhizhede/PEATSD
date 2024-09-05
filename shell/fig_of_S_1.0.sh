#!/bin/bash

# input: PRO, OBJ, VAR, ALG, RUN
source ./Args_for_shell.sh

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
	h5=$h4/S
	h6=$h5/RUN$(printf '%03d' $run)

	if [  -d $h6 ]; then
		# matlab script	for getting a row of data
		matscript=/tmp/mat$$$$.m
		touch $matscript
		echo "A=[" > $matscript
		cat ${h6}/$(ls ${h6} | head -n 101 | tail -n 1) >> $matscript
		echo "];" >> $matscript
		if [ $obj -eq 2 ]; then
			echo "scatter(A(3:end,1),A(3:end,2));" >> $matscript
		else
			echo "scatter3(A(:,1),A(:,2), A(:,3));" >> $matscript
		fi
echo "title('Similarity of ${pro} with $obj objectives and $var variables');" >> $matscript
echo "print('tmp/S-${pro}-$(printf '%02d' $obj)-$(printf '%05d' $var)-$(printf '%03d' $run)','-depsc');" >> $matscript

		# run matlab script
		octave-cli $matscript
		rm $matscript
	else
		echo "ERROR: Directory $h6 does not exits."
		echo "Maybe forget to make the tree."
		exit
	fi	
done
done
done
done
done
