#!/bin/bash

# input: PRO, OBJ, VAR, ALG, RUN
source ./Args_for_shell.sh

# 
for run in $(seq 1 $RUN); do
for pro in ${PRO}; do
for obj in ${OBJ}; do 			
for var in ${VAR}; do

	# matlab script	for getting a row of data
	matscript=/tmp/mat$$$$.m
	touch $matscript

	for alg in ${ALG}; do
		root="./tmp/OUTPUT"		
		h1=$root/$pro
		h2=$h1/OBJ$(printf '%02d' $obj)
		h3=$h2/VAR$(printf '%05d' $var)
		h4=$h3/$alg
		h5=$h4/time
		h6=$h5/RUN$(printf '%03d' $run)


		if [  -d $h6 ]; then
			echo "$alg=[" >> $matscript
			cat $h6/* >> $matscript
			echo "];" >> $matscript
		else
			echo "ERROR: Directory $h6 does not exits."
			echo "Maybe forget to make the tree."
			exit
		fi	
	done

	# 
	echo -n "plot(" >> $matscript
	Marker="o+*.xsd^v<>ph"
	i=0;
	for alg in $ALG; do
		echo -n "0:1:size($alg, 1)-1, $alg(:,1),  'marker', '${Marker:${i}:1}'," >> $matscript
		i=$[ $i + 1 ]
	done
	echo "'LineWidth', 2.8);" >> $matscript
	echo "box on" >> $matscript
	echo "legend('${ALG// /\', \'}');" >> $matscript
	echo "title('The running time on ${pro} with $obj objectives and $var variables for run $run');" >> $matscript
	echo "print('tmp/Time-${pro}-$(printf '%02d' $obj)-$(printf '%05d' $var)-$(printf '%03d' $run)','-depsc');" >> $matscript

	# run matlab script
	octave-cli $matscript
	rm $matscript
done
done
done
done
