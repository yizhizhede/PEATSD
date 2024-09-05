#!/bin/bash

# input: PRO, OBJ, VAR, ALG, RUN
source ./Args_for_shell.sh

for pro in ${PRO}; do
for obj in ${OBJ}; do 			
for var in ${VAR}; do
for alg in ${ALG}; do
for run in $(seq 1 ${RUN}); do
	root="./tmp/OUTPUT"		
	h1=$root/$pro
	h2=$h1/OBJ$(printf '%02d' $obj)
	h3=$h2/VAR$(printf '%05d' $var)
	h4=$h3/$alg
	if [ -d $h4 ]; then
		for typ in $(ls $h4); do
			h5=$h4/$typ
			h6=$h5/RUN$(printf '%03d' $run)
			if [ -d $h6 ]; then
				startfile=$(ls $h6 | head -n 1)
				startNo=${startfile:0-3:3}
	
				nFile=0
				for file in $(ls $h6/*); do 
					nFile=$[ $nFile + 1 ]
					No=${file:0-3:3}
					if [ $No = $startNo ] && [ $nFile -ne 1 ] ; then
						echo "removing" 
						ls $h6/* | head -n $[ $nFile - 1 ]
						rm -f $(ls $h6/* | head -n $[ $nFile - 1 ])
						break
					fi
				done

			fi	
		done
	fi
done
done
done
done
done
