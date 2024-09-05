#!/bin/bash

# input: PRO, OBJ, VAR, ALG, RUN
source ./Args_for_shell.sh

#
for pro in ${PRO}; do
for obj in ${OBJ}; do 			
for var in ${VAR}; do
	# matlab script	for getting a row of data
	matscript=./tmp/IGD${pro}O$(printf '%02d' $obj)V$(printf '%05d' $var).m
	cat /dev/null > $matscript

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
				echo "${alg}${run}igd=[" >> $matscript
				cat $h6/* >> $matscript
				echo "];" >> $matscript
			else
				echo "ERROR: Directory $h6 does not exits."
				echo "Maybe forget to make the tree."
				exit
			fi	

			root="./tmp/OUTPUT"		
			h1=$root/$pro
			h2=$h1/OBJ$(printf '%02d' $obj)
			h3=$h2/VAR$(printf '%05d' $var)
			h4=$h3/$alg
			h5=$h4/fitness
			h6=$h5/RUN$(printf '%03d' $run)

			if [  -d $h6 ]; then
				echo "${alg}${run}fitness=[" >> $matscript
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
		echo "${alg}igd=[];" >> $matscript
		echo "${alg}fitness=[];" >> $matscript
		echo "L=[];" >> $matscript
		echo "N=[];" >> $matscript
		echo "I=[];" >> $matscript

		for run in $(seq 1 $RUN); do
			echo "I=find(L == size(${alg}${run}fitness, 1));" >> $matscript
			echo "if size(I, 1) < 1 || size(I, 2) < 1" >> $matscript
			echo "L=[L; size(${alg}${run}fitness, 1)];" >> $matscript
			echo "N=[N; 1];" >> $matscript
			echo "else" >> $matscript
			echo "N(I)=N(I) + 1;" >> $matscript
			echo "end" >> $matscript
		done
		echo "[~,I]=max(N,[],1);" >> $matscript
		echo "N=L(I);" >> $matscript

		for run in $(seq 1 $RUN); do
			echo "if N == size(${alg}${run}fitness, 1)" >> $matscript
			echo "${alg}igd=[${alg}igd,${alg}${run}igd];" >> $matscript
			echo "${alg}fitness=[${alg}fitness,${alg}${run}fitness];" >> $matscript
			echo "end" >> $matscript
		done

		echo "if (size(${alg}igd,2) > 1)" >> $matscript
		echo "${alg}igd=mean(${alg}igd,2);" >> $matscript
		echo "${alg}fitness=mean(${alg}fitness,2);" >> $matscript
		echo "end" >> $matscript
	done

	# The entire plot
	echo -n "semilogy(" >> $matscript
	Marker="op*^hsdv<>ph"
	i=0;
	for alg in $ALG; do
		echo -n "${alg}fitness, ${alg}igd, '-${Marker:${i}:1}', " >> $matscript
		i=$[ $i + 1 ]
	done
	echo "'LineWidth', 1);" >> $matscript
	echo "box on" >> $matscript
	echo "xlabel('Number of Function Evaluations');" >> $matscript
	echo "ylabel('IGD Value')" >> $matscript
	echo "title ('$pro with $obj objectives and $var variables', 'FontWeight','bold');" >> $matscript
#	echo "xlim([0, 10^7]);" >> $matscript
	echo "set(gca,'YminorTick','off');" >> $matscript

	#
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
	legend=${legend/MOEATPS/MOEA\/TPS}
	legend=${legend// /  \', \'}
	echo "h=legend('$legend', 'Location', 'northeast');" >> $matscript
	echo "set(h, 'fontsize', 7);" >> $matscript
	echo "set(gca, 'FontName', 'Times New Roman','FontSize', 14, 'FontWeight', 'bold');" >> $matscript
	echo "print('tmp/IGD-${pro}-$(printf '%02d' $obj)-$(printf '%05d' $var)','-depsc');" >> $matscript

	# run matlab script
	octave-cli $matscript
done
done
done
