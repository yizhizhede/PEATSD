#!/bin/bash

# input: PRO, OBJ, VAR, ALG, RUN
source ./Args_for_shell.sh

for pro in ${PRO}; do
for obj in ${OBJ}; do 			
for var in ${VAR}; do
for alg in ${ALG}; do
	# matlab script	for getting run number
	matscript=/tmp/mat$$$$.m
	touch $matscript
	echo "M=[" > $matscript
	for run in $(seq 1 $RUN); do
		root="./tmp/OUTPUT"		
		h1=$root/$pro
		h2=$h1/OBJ$(printf '%02d' $obj)
		h3=$h2/VAR$(printf '%05d' $var)
		h4=$h3/$alg
		h5=$h4/igd
		h6=$h5/RUN$(printf '%03d' $run)
		if [ -d $h6 ]; then
			cat ${h6}/$(ls ${h6} | tail -n 1) >> $matscript
		else
			echo "ERROR: Directory $h6 does not exits."
			echo "Maybe forget to make the tree."
			exit
		fi	
	done
	echo "];" >> $matscript
	echo "[B, I]=sort(M);" >> $matscript
	echo "i=ceil(size(M, 1)/2.0);" >> $matscript
	echo "printf('%d', I(i));" >> $matscript

	#
	run=$(octave-cli $matscript)
	rm -f $matscript

	# matlab script	for getting a row of data
	matscript=/tmp/mat$$$$.m
	touch $matscript

	root="./tmp/OUTPUT"		
	h1=$root/$pro
	h2=$h1/OBJ$(printf '%02d' $obj)
	h3=$h2/VAR$(printf '%05d' $var)
	h4=$h3/$alg
	h5=$h4/var
	h6=$h5/RUN$(printf '%03d' $run)

	if [ -d $h6 ]; then
		echo "M=[" >> $matscript
		cat ${h6}/$(ls ${h6} | head -n 101 | tail -n 1) >> $matscript
		echo "];" >> $matscript
		echo "M=sortrows(M);" >> $matscript
	else
		echo "ERROR: Directory $h6 does not exits."
		echo "Maybe forget to make the tree."
		exit
	fi	


	echo "plot(M(:,1),M(:,2),'-o','MarkerEdgeColor','b','MarkerFaceColor','b');" >> $matscript
	echo "box on" >> $matscript
	echo "xlabel('First Decision Variable');" >> $matscript
	echo "ylabel('Second Decision Variable');" >> $matscript
	echo "title('${alg} on ${pro} with $obj objectives and $var variables');" >> $matscript
	echo "print('tmp/Var-${pro}-$(printf '%02d' $obj)-$(printf '%05d' $var)-$alg','-depsc');" >> $matscript

	# run matlab script
	octave-cli $matscript
	rm $matscript
done
done
done
done
