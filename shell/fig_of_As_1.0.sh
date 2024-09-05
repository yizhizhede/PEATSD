#!/bin/bash

# input: PRO, OBJ, VAR, ALG, RUN
source ./Args_for_shell.sh

# for run in $(seq 1 $RUN); do
for run in 1; do
for pro in ${PRO}; do
for obj in ${OBJ}; do 			
for var in ${VAR}; do
for alg in ${ALG}; do
	# matlab script	for getting a row of data
	matscript=/tmp/mat$$$$.m
	touch $matscript

	root="./tmp/OUTPUT"		
	h1=$root/$pro
	h2=$h1/OBJ$(printf '%02d' $obj)
	h3=$h2/VAR$(printf '%05d' $var)
	h4=$h3/$alg
	h5=$h4/A
	h6=$h5/RUN$(printf '%03d' $run)
	if [  -d $h6 ]; then
		echo "A=[" >> $matscript
		cat ${h6}/$(ls ${h6} | tail -n 1) >> $matscript
		echo "];" >> $matscript
	else
		rm $matscript
		echo "ERROR: Directory $h6 does not exits."
		echo "Maybe forget to make the tree."
		exit
	fi	
	h5=$h4/s
	h6=$h5/RUN$(printf '%03d' $run)
	if [  -d $h6 ]; then
		echo "s=[" >> $matscript
		cat ${h6}/$(ls ${h6} | tail -n 1) >> $matscript
		echo "];" >> $matscript
	else
		rm $matscript
		echo "ERROR: Directory $h6 does not exits."
		echo "Maybe forget to make the tree."
		exit
	fi	

	echo "subplot(6,1,1)" >> $matscript
	echo "plot(1:$var, A(1:$var,:),'marker', 'o', 'LineWidth', 2.8);" >> $matscript
	echo "box on" >> $matscript
	echo "title('Angle and shift of ${pro} with $obj objectives and $var variables');" >> $matscript

	echo "subplot(6,1,2)" >> $matscript
	echo "plot(1:$var, s(1:$var,:),'marker', 'o', 'LineWidth', 2.8);" >> $matscript

	echo "subplot(6,1,3)" >> $matscript
	echo "plot(2:$var, A(2:$var,:),'marker', 'o', 'LineWidth', 2.8);" >> $matscript

	echo "subplot(6,1,4)" >> $matscript
	echo "plot(2:$var, s(2:$var,:),'marker', 'o', 'LineWidth', 2.8);" >> $matscript

	echo "subplot(6,1,5)" >> $matscript
	echo "plot(3:$var, A(3:$var,:),'marker', 'o', 'LineWidth', 2.8);" >> $matscript

	echo "subplot(6,1,6)" >> $matscript
	echo "plot(3:$var, s(3:$var,:),'marker', 'o', 'LineWidth', 2.8);" >> $matscript

echo "print('tmp/As-${pro}-$(printf '%02d' $obj)-$(printf '%05d' $var)-$(printf '%03d' $run)','-depsc');" >> $matscript

	# run matlab script
	octave-cli $matscript
	rm $matscript
done
done
done
done
done
