#!/bin/bash

# input: PRO, OBJ, VAR, ALG, RUN
source ./Args_for_shell.sh

#
for pro in ${PRO}; do
for obj in ${OBJ}; do 			
for var in ${VAR}; do
	# matlab script	for getting a row of data
	matscript=./tmp/BoxPlotHV${pro}O$(printf '%02d' $obj)V$(printf '%05d' $var).m
	cat /dev/null > $matscript

	for alg in ${ALG}; do
		echo "${alg}hv=[" >> $matscript
		for run in $(seq 1 $RUN); do
			root="./tmp/OUTPUT"		
			h1=$root/$pro
			h2=$h1/OBJ$(printf '%02d' $obj)
			h3=$h2/VAR$(printf '%05d' $var)
			h4=$h3/$alg
			h5=$h4/hv
			h6=$h5/RUN$(printf '%03d' $run)

			if [  -d $h6 ]; then
				cat $( ls $h6/* | tail -n 1 ) >> $matscript
			else
				echo "ERROR: Directory $h6 does not exits."
				echo "Maybe forget to make the tree."
				exit
			fi	
		done
		echo "];" >> $matscript
	done

	# Data
	echo -n "Data=[" >> $matscript
	for alg in $ALG; do
		echo -n "${alg}hv," >> $matscript
	done
	echo "];" >> $matscript

	# Labels
	legend=$ALG
	legend=${legend/SNSGAII/S-NSGA-II}
	legend=${legend/NSGAII/NSGA-II}
	legend=${legend/MOEAD/MOEA\/D}
	legend=${legend/NSGAIII/NSGA-III}
	legend=${legend/SMSEMOA/SMS-EMOA}
	legend=${legend/TWOARCH2/Two\\_Arch2}
	legend=${legend/MOEADVA/MOEA\/DVA}
	legend=${legend/DLSMOEA/DLS-MOEA}
	legend=${legend/MPMMEA/MP-MMEA}
	legend=${legend/ALMOEA/AMOEA\/D}
	legend=${legend/WOF/WOF-SMPSO}
	legend=${legend/MOEATSS/MOEA\/TSD}
	legend=${legend/MOEATSS/MOEA\/TSS}
	legend=${legend// /  \', \'}

	# box-plot
	# echo "pkg load statistics" >> $matscript
	echo "boxplot(Data, 'Labels', {'$legend'}, 'LabelOrientation','horizontal');" >> $matscript
	echo "set(gca, 'FontName', 'Times New Roman','FontSize', 14, 'FontWeight', 'bold');" >> $matscript
	echo "ylabel('HV Value')" >> $matscript
	echo "title ('$pro with $obj objectives and $var variables', 'FontWeight','bold');" >> $matscript
	echo "set(gca,'YminorTick','off');" >> $matscript
	# echo "print('tmp/Box-HV-${pro}-$(printf '%02d' $obj)-$(printf '%05d' $var)','-depsc');" >> $matscript
	echo "print('Box-HV-${pro}-$(printf '%02d' $obj)-$(printf '%05d' $var)','-depsc');" >> $matscript

	# run matlab script
	# octave-cli $matscript
done
done
done
