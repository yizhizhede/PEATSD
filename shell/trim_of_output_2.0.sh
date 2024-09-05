#!/bin/bash

# PRO
PRO="WFG8 WFG9"
PRO="WFG1 WFG2 WFG3 WFG4 WFG5 WFG6 WFG7 WFG8 WFG9"
PRO="DTLZ1 DTLZ2 DTLZ3 DTLZ4 DTLZ5 DTLZ6 DTLZ7" 
PRO="DTLZ1 DTLZ2 DTLZ3 DTLZ4 DTLZ5 DTLZ6 DTLZ7 WFG1 WFG2 WFG3 WFG4 WFG5 WFG6 WFG7 WFG8 WFG9"
PRO="WFG9"

# OBJ
OBJ="2 3" 						
OBJ="2" 	

# VAR
VAR="8 16 32 64 128 256 512 1024" 		
VAR="5" 		

# ALG
ALG="NSGAII MOEAD NSGAIII TWOARCH2 NSEA"
ALG="NSEA"

# RUN
RUN=20
RUN=1

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
for typ in $(ls $h4); do
	h5=$h4/$typ
	h6=$h5/RUN$(printf '%03d' $run)

	echo "removing $h6"
	if [  -d $h6 ]; then
		rm -r $h6 
	fi	
done
done
done
done
done
done
