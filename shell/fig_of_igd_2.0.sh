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

	for alg in ${ALG}; do
		for run in $(seq 1 $RUN); do
			root="./tmp/OUTPUT"		
			h1=$root/$pro
			h2=$h1/OBJ$(printf '%02d' $obj)
			h3=$h2/VAR$(printf '%05d' $var)
			h4=$h3/$alg
			h5=$h4/igd
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
		done
	done
	for alg in ${ALG}; do
		echo "$alg=[];" >> $matscript
		for run in $(seq 1 $RUN); do
			echo "$alg=[$alg,$alg$run];" >> $matscript
		done
	done
	echo "if (size($alg,2) > 1)" >> $matscript
	echo "$alg=mean($alg')';" >> $matscript
	echo "end" >> $matscript

	# The entire plot
	echo "figure('Units', 'centimeters','PaperPosition', [0 0 5 5]);" >> $matscript
	echo -n "plot(" >> $matscript
	Marker="o+*.xsd^v<>ph"
	i=0;
	for alg in $ALG; do
		echo -n "0:5:size($alg, 1)-1, log($alg(1:5:end,1)), 'marker', '${Marker:${i}:1}', 'LineWidth', 2.8, " >> $matscript
		i=$[ $i + 1 ]
	done
	echo "'LineWidth', 2.8);" >> $matscript
	echo "box off" >> $matscript
	echo "xlabel('Progress (%)')" >> $matscript
	echo "ylabel('Logarithm of IGD')" >> $matscript

	#
	legend=$ALG
	legend=${legend/NSGAII/NSGA-II}
	legend=${legend/MOEAD/MOEA\/D}
	legend=${legend/NSGAIII/NSGA-III}
	legend=${legend/SMSEMOA/SMS-EMOA}
	legend=${legend/TWOARCH2/Two\\_Arch2}
	legend=${legend/MOEADVA/MOEA\/DVA}
	legend=${legend/DLSMOEA/DLS-MOEA}
	legend=${legend/MPMMEA/MP-MMEA}
	legend=${legend// /\', \'}
	echo "legend('$legend', 'Location', 'northeast');" >> $matscript
	echo "legend('boxoff');" >> $matscript
#	echo "title('${pro} with $obj objectives and $var variables');" >> $matscript
	echo "print('tmp/IGD-${pro}-$(printf '%02d' $obj)-$(printf '%05d' $var)','-depsc');" >> $matscript

	# The part of plot
if false; then
for s in 1 21 41 61 81; do
	echo -n "plot(" >> $matscript
	Marker="o+*.xsd^v<>ph"
	i=0;
	for alg in $ALG; do
		echo -n "$[ $s - 1 ]:1:$[ $s + 19 ], $alg(${s}:$[ $s + 20 ],1),  'marker', '${Marker:${i}:1}'," >> $matscript
		i=$[ $i + 1 ]
	done
	echo "'LineWidth', 2.8);" >> $matscript
	echo "box off" >> $matscript
	echo "legend('${ALG// /\', \'}');" >> $matscript
	echo "title('${pro} with $obj objectives and $var variables');" >> $matscript
	echo "print('tmp/IGD-${pro}-$(printf '%02d' $obj)-$(printf '%05d' $var)-$(printf '%02d' $s)', '-dpng');" >> $matscript
done
fi

	# run matlab script
	octave-cli $matscript
	rm $matscript
done
done
done

