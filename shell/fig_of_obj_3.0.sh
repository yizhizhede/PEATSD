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
	matscript=./tmp/Obj${pro}O$(printf '%02d' $obj)V$(printf '%05d' $var)A$alg.m
	cat /dev/null > $matscript
	cat matlab/Problem_Sample.m > $matscript

	# get H
	echo "H=${pro}O$(printf '%02d' $obj);" >> $matscript

	# get M
	root="./tmp/OUTPUT"		
	h1=$root/$pro
	h2=$h1/OBJ$(printf '%02d' $obj)
	h3=$h2/VAR$(printf '%05d' $var)
	h4=$h3/$alg
	h5=$h4/obj
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

	# displayname
	displayname=$alg
	displayname=${displayname/SNSGAII/S-NSGA-II}
	displayname=${displayname/NSGAII/NSGA-II}
	displayname=${displayname/MOEAD/MOEA\/D}
	displayname=${displayname/NSGAIII/NSGA-III}
	displayname=${displayname/SMSEMOA/SMS-EMOA}
	displayname=${displayname/TWOARCH2/Two\\_Arch2}
	displayname=${displayname/MOEADVA/MOEA\/DVA}
	displayname=${displayname/DLSMOEA/DLS-MOEA}
	displayname=${displayname/MPMMEA/MP-MMEA}
	displayname=${displayname/ALMOEA/AMOEA\/D}
	displayname=${displayname/WOF/WOF-SMPSO}
	displayname=${displayname/MOEATSS/MOEA\/TSD}
	displayname=${displayname/MOEATPS/MOEA\/TPS}
	
# plot	
if [ $obj -eq 2 ]; then

	# The entire plot
	echo "figure1=figure;" >> $matscript
	echo "axes1=axes('Parent', figure1);" >> $matscript
	echo "hold(axes1, 'on');" >> $matscript
	echo "scatter(M(:,1), M(:,2), 'Marker', 'o', 'MarkerEdgeColor', 'b', 'MarkerFaceColor', 'b', 'DisplayName', '$displayname', 'Parent', axes1);" >> $matscript
	echo "plot(H(:,1), H(:,2), '-m', 'DisplayName', 'true PF', 'Parent', axes1, 'LineWidth', 1);" >> $matscript
	echo "box(axes1, 'on')" >> $matscript
	echo "xlabel(axes1, 'f1');" >> $matscript
	echo "ylabel(axes1, 'f2');" >> $matscript
	echo "legend(axes1, 'show', 'Location', 'northeast');" >> $matscript
	echo "title(axes1, '${pro} with $obj objectives $var variables', 'FontWeight', 'bold');" >> $matscript
	echo "set(gca, 'FontName', 'Times New Roman',  'FontSize', 18, 'FontWeight', 'bold');" >> $matscript
	echo "hold(axes1, 'off');" >> $matscript
	echo "print(figure1, 'tmp/Obj-${pro}-$(printf '%02d' $obj)-$(printf '%05d' $var)-$alg','-depsc');" >> $matscript

elif [ $obj -eq 3 ]; then

	# The entire plot
	echo "figure1 = figure;" >> $matscript
	echo "axes1 = axes('Parent', figure1);" >> $matscript
	echo "hold(axes1, 'on');" >> $matscript

	# true PF
if [ $pro = UF8 ] || [ $pro = UF10 ] || [ $pro = LSMOP5 ] || [ $pro = LSMOP6 ] || [ $pro = LSMOP7 ]  || [ $pro = LSMOP8 ] || [ $pro = BT9 ]; then
	echo "[fia,theta]=meshgrid(linspace(0,acos(0),15));" >> $matscript
	echo "X=sin(theta).*cos(fia);" >> $matscript
	echo "Y=sin(theta).*sin(fia);" >> $matscript
	echo "Z=cos(theta);" >> $matscript
	echo "mesh(X, Y, Z, 'DisplayName', 'true PF', 'Parent', axes1, 'EdgeColor','k');" >> $matscript
	echo "axis([0,1,0,1]);" >> $matscript
elif [ $pro = LSMOP1 ] || [ $pro = LSMOP2 ] || [ $pro = LSMOP3 ] || [ $pro = LSMOP4 ]; then
	echo "[X,Y]=meshgrid(linspace(0,1,15));" >> $matscript
	echo "Z= 1 - X - Y;" >> $matscript
	echo "mesh(X, Y, Z, 'DisplayName', 'true PF', 'Parent', axes1, 'EdgeColor','k');" >> $matscript
	echo "plot3([1,0], [0,1], [0,0], '-k');" >> $matscript
	echo "axis([0,1,0,1,0,1]);" >> $matscript
else
	echo "scatter3(H(:,1), H(:,2), H(:,3), 'DisplayName', 'true PF', 'Parent', axes1, 'Marker', '.', 'MarkerEdgeColor', 0.8.*[1 1 1], 'MarkerFaceColor', 0.8.*[1 1 1]);" >> $matscript
	echo "axis([0,1,0,1]);" >> $matscript
fi

	# PF obtained by algorithm
	echo "scatter3(M(:,1), M(:,2), M(:,3), 'DisplayName', '$displayname', 'Parent', axes1, 'Marker', 'o', 'MarkerEdgeColor', 'r', 'MarkerFaceColor', 'r');" >> $matscript

	# set 
	echo "box(axes1, 'off');" >> $matscript
	echo "grid(axes1, 'off');" >> $matscript
	echo "view(axes1, [135, 30]);" >> $matscript
	echo "xlabel(axes1, 'f1');" >> $matscript
	echo "ylabel(axes1, 'f2');" >> $matscript
	echo "zlabel(axes1, 'f3');" >> $matscript
	echo "title(axes1, '$displayname on ${pro} with $obj objectives $var variables', 'FontWeight', 'bold');" >> $matscript
	echo "set(gca, 'FontName', 'Times New Roman',  'FontSize', 18, 'FontWeight', 'bold');" >> $matscript
	# echo "legend(axes1, 'truePF', '$alg', 'Location', 'best');" >> $matscript
	echo "hold(axes1, 'off');" >> $matscript
	echo "print(figure1, 'tmp/Obj-${pro}-$(printf '%02d' $obj)-$(printf '%05d' $var)-$alg','-depsc');" >> $matscript
fi

	# run matlab script
	octave-cli $matscript
done
done
done
done
