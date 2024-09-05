#!/bin/bash

# input: PRO, OBJ, VAR, ALG, RUN
source ./Args_for_shell.sh

#
for pro in ${PRO}; do
for obj in ${OBJ}; do 			
for var in ${VAR}; do
	# matlab script	for getting a row of data
	matscript=/tmp/mat$$$$.m
	touch $matscript

	for run in $(seq 1 $RUN); do
		root="./tmp/OUTPUT"		
		h1=$root/$pro
		h2=$h1/OBJ$(printf '%02d' $obj)
		h3=$h2/VAR$(printf '%05d' $var)
		h4=$h3/SPCEA
		h5=$h4/ash
		h6=$h5/RUN$(printf '%03d' $run)

		if [  -d $h6 ]; then
			echo "SPCEA$run=[" >> $matscript
			cat $h6/$(ls ${h6} | tail -n 1) >> $matscript
			echo "];" >> $matscript
		else
			echo "ERROR: Directory $h6 does not exits."
			exit
		fi	
	done

	# the entire flowchart
	for i in $(seq 1 $RUN); do
		echo "h1=figure('Units', 'centimeters','PaperPosition', [0 0 5 5]);" >> $matscript
	#	echo "hold on;" >> $matscript
	#	echo "subplot($[ $RUN / 2 + $RUN % 2 ], 2, ${i});" >> $matscript
		echo "M=SPCEA${i}';" >> $matscript
	echo "plot (M(1, :), 10000.*M(2, :), 'LineWidth', 2.8, 'Marker', 'o', 'MarkerSize', 3, 'Color', 'k')" >> $matscript
		echo "box on;" >> $matscript
       	#	echo "title('RUN: ${i}');" >> $matscript
		echo "xlabel('Sequence number');" >> $matscript
		echo "ylabel('k\\lambda, k=10000');" >> $matscript
	echo "print('tmp/Ash-${pro}-$(printf '%02d' $obj)-$(printf '%05d' $var)-$(printf '%03d' $i)','-depsc');" >> $matscript
	done


	# run matlab script
	octave-cli $matscript
	rm $matscript
done
done
done

