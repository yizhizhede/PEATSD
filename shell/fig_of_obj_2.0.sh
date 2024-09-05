#!/bin/bash

# input: PRO, OBJ, VAR, ALG, RUN
source ./Args_for_shell.sh

for run in $(seq 1 $RUN); do
for pro in ${PRO}; do
for obj in ${OBJ}; do 			
for var in ${VAR}; do

	# matlab script	for getting a row of data
	matscript=/tmp/mat$$$$.m
	touch $matscript

	for alg in ${ALG}; do
		root="./tmp/OUTPUT"		
		h1=$root/$pro
		h2=$h1/OBJ$(printf '%02d' $obj)
		h3=$h2/VAR$(printf '%05d' $var)
		h4=$h3/$alg
		h5=$h4/obj
		h6=$h5/RUN$(printf '%03d' $run)


		if [  -d $h6 ]; then
			echo "$alg=[" >> $matscript
			cat ${h6}/$(ls ${h6} | head -n 101 | tail -n 1) >> $matscript
			echo "];" >> $matscript
			echo "$alg=sortrows($alg);" >> $matscript
		else
			echo "ERROR: Directory $h6 does not exits."
			echo "Maybe forget to make the tree."
			exit
		fi	
	done

if [ $obj -eq 2 ]; then
	# The entire plot
	echo "figure;" >> $matscript
	echo "hold on;" >> $matscript
	Marker="o+*.xsd^v<>ph"
	i=0;
	echo "figure('Units', 'centimeters','PaperPosition', [0 0 5 5]);" >> $matscript
	echo -n "plot(" >> $matscript
	for alg in $ALG; do
		echo -n "$alg(:,1), $alg(:,2), 'marker', '${Marker:${i}:1}', 'LineWidth', 1.4, " >> $matscript
		i=$[ $i + 1 ]
	done
	echo "'LineWidth', 1.4);" >> $matscript
	echo "box off" >> $matscript
	echo "xlabel('f1');" >> $matscript
	echo "ylabel('f2');" >> $matscript
	echo "legend('${ALG// /\', \'}');" >> $matscript
	echo "legend('boxoff');" >> $matscript
	echo "title('${pro} with $obj objectives and $var variables');" >> $matscript
	echo "print('tmp/Obj-${pro}-$(printf '%02d' $obj)-$(printf '%05d' $var)-$(printf '%03d' $run)','-depsc');" >> $matscript
elif [ $obj -eq 3 ]; then
	# The entire plot
for alg in $ALG; do
	echo "figure('Units', 'centimeters','PaperPosition', [0 0 5 5]);" >> $matscript
	echo "scatter3($alg(:,1), $alg(:,2), $alg(:,3), 'marker', 'o',  'MarkerEdgeColor','k', 'MarkerFaceColor',[0 .75 .75])" >> $matscript
	echo "box off" >> $matscript
	echo "grid on" >> $matscript
#	echo "view (45, 30);" >> $matscript
	echo "view ([1, 1, 1]);" >> $matscript
	echo "xlabel('f1');" >> $matscript
	echo "ylabel('f2');" >> $matscript
	echo "zlabel('f3');" >> $matscript
#	echo "title('$alg on ${pro} with $obj objectives and $var variables');" >> $matscript
	echo "print('tmp/Obj-${pro}-$(printf '%02d' $obj)-$(printf '%05d' $var)-$(printf '%03d' $run)-$alg','-depsc');" >> $matscript
done
fi

	# run matlab script
	octave-cli $matscript
	rm $matscript
done
done
done
done
