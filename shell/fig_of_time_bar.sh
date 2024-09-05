#!/bin/bash

# input: PRO, OBJ, VAR, ALG, RUN
source ./Args_for_shell.sh

#
for pro in ${PRO}; do
for obj in ${OBJ}; do 			
for var in ${VAR}; do
	# matlab script	for getting a row of data
	matscript=./tmp/Bar${pro}O$(printf '%02d' $obj)V$(printf '%05d' $var).m
	cat /dev/null >  $matscript

	for alg in ${ALG}; do
		echo "$alg=[];" >> $matscript
		for run in $(seq 1 $RUN); do
			root="./tmp/OUTPUT"		
			h1=$root/$pro
			h2=$h1/OBJ$(printf '%02d' $obj)
			h3=$h2/VAR$(printf '%05d' $var)
			h4=$h3/$alg
			h5=$h4/time
			h6=$h5/RUN$(printf '%03d' $run)

			if [  -d $h6 ]; then
				echo "$alg$run=[" >> $matscript
				cat $h6/* >> $matscript
				echo "];" >> $matscript
			else
				echo "ERROR: Directory $h6 does not exits."
				echo "Maybe forget to make the tree."
				exit
			fi	

			echo "$alg=[$alg; $alg$run(end,end)];" >> $matscript
		done
	done

	# Time
	echo "T=[];" >> $matscript
	for alg in $ALG; do
		echo "T=[T, mean($alg)];" >> $matscript
	done

	# X
	X=$ALG
	X=${X/NSGAII/NSGA-II}
	X=${X/MOEAD/MOEA\/D}
	X=${X/NSGAIII/NSGA-III}
	X=${X/SMSEMOA/SMS-EMOA}
	X=${X/TWOARCH2/Two\\_Arch2}
	X=${X/MOEADVA/MOEA\/DVA}
	X=${X/DLSMOEA/DLS-MOEA}
	X=${X/MPMMEA/MP-MMEA}
	X=${X/MOEATSS/MOEA\/TSS}
	X=${X// /\', \'}
	echo "X=categorical({'$X'});" >> $matscript
	echo "X=reordercats(X, {'$X'});" >> $matscript

	# bar
	echo "bar (X,T);" >> $matscript
	echo "ylabel('Runing time(s)');" >> $matscript
	echo "title('$pro with $obj objectives and $var variables');" >> $matscript
	echo "grid on" >> $matscript
	echo "print('Bar-${pro}-$(printf '%02d' $obj)-$(printf '%05d' $var)','-depsc');" >> $matscript

	# run matlab script
	# octave-cli $matscript
done
done
done
