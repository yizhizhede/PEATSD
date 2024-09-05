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
                                echo "if size($alg$run, 1) < 21" >> $matscript  	# 1-21 rows
                                echo "$alg$run=[$alg$run;$alg$run(end,1).*ones([21-size($alg$run,1),1])];" >> $matscript
                                echo "end" >> $matscript  	
				echo "$alg$run(21,:)=$alg$run(end,:);" >> $matscript	# 1-21 rows
				echo "$alg$run=$alg$run(1:21,1);" >> $matscript		# 1-21 rows
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
		echo -n "0:5:100, log10($alg(1:1:21,1)), 'marker', '${Marker:${i}:1}', 'LineWidth', 2.8, " >> $matscript
		i=$[ $i + 1 ]
	done
	echo "'LineWidth', 2.8);" >> $matscript
	echo "box on" >> $matscript
	echo "pos=axis;" >> $matscript
#	echo "text('Position',[0.86*pos(2) pos(3)-0.05*(pos(4)-pos(3))],'String','\times 10^6');" >> $matscript
	echo "xlabel('FEs(%)','position', [0 0]);" >> $matscript
	echo "ylabel('log(igd)')" >> $matscript

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
	legend=${legend// /  \', \'}
	echo "h=legend('$legend', 'Location', 'northeast');" >> $matscript
	echo "set(h, 'fontsize', 7);" >> $matscript
#	echo "title('${pro} with $obj objectives and $var variables');" >> $matscript
	echo "print('tmp/IGD-${pro}-$(printf '%02d' $obj)-$(printf '%05d' $var)','-depsc');" >> $matscript

	# run matlab script
	octave-cli $matscript
	rm $matscript
done
done
done
