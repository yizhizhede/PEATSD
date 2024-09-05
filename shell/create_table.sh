#!/bin/bash

#######################################################################################################
PRO=""
OBJ=""
VAR=""
ALG=""

for file in output/*_front_*; do
	stock=${file##*/}
	pro=$(echo $stock | sed 's/^\([A-Z]*[0-9]*\)o\([0-9]*\)v\([0-9]*\)_\([A-Z]*.*\)_front_.*$/\1/g' )
	obj=$(echo $stock | sed 's/^\([A-Z]*[0-9]*\)o\([0-9]*\)v\([0-9]*\)_\([A-Z]*.*\)_front_.*$/\2/g' )
	var=$(echo $stock | sed 's/^\([A-Z]*[0-9]*\)o\([0-9]*\)v\([0-9]*\)_\([A-Z]*.*\)_front_.*$/\3/g' )
	alg=$(echo $stock | sed 's/^\([A-Z]*[0-9]*\)o\([0-9]*\)v\([0-9]*\)_\([A-Z]*.*\)_front_.*$/\4/g' )

	len=$(echo $PRO | grep $pro)
	if [ "$len" = "" ] ; then
		PRO="$PRO $pro"
	fi

	len=$(echo $OBJ | grep $obj)
	if [ "$len" = "" ] ; then
		OBJ="$OBJ $obj"
	fi

	len=$(echo $VAR | grep $var)
	if [ "$len" = "" ] ; then
		VAR="$VAR $var"
	fi

	len=$(echo $ALG | grep $alg)
	if [ "$len" = "" ] ; then
		ALG="$ALG $alg"
	fi
done

arr=($ALG)
nAgl=${#arr[@]}
arr=($OBJ)
nObj=${#arr[@]}
arr=($VAR)
nVar=${#arr[@]}

ofs="latex/table.tex"
echo "\\documentclass{IEEEtran}" > $ofs
# echo "\\usepackage{booktabs}" >> $ofs
# echo "\\usepackage{xcolor}" >> $ofs
# echo "\\usepackage{multirow}" >> $ofs
echo "\\input{/Users/fengyin/Documents/writing/package.tex}" >> $ofs
echo "\\begin{document}" >> $ofs

###################################################################################################################
################################# Table 1. Count of front with (Pro. Obj. Var. Alg) ###############################
###################################################################################################################
if false; then
echo "\\begin{table*}" >> $ofs
echo "\\centering" >> $ofs
echo "\\caption{The number of runing of each alorithm for problems}" >> $ofs

echo "\\begin{tabular}{*{$[ $nAgl + 3]}{c}}" >> $ofs
echo "\\toprule" >> $ofs
echo "Pro. & Obj. & Var. & $(echo $ALG | sed 's/ / \& /g') \\\\" >> $ofs
echo "\\midrule" >> $ofs

item=0
for pro in $PRO; do
	item1="\\multirow{$[ $nObj * $nVar ]}*{$pro}"	
	for obj in $OBJ; do
		item2="\\multirow{$nVar}*{$(echo ${obj} | sed 's/^0*\([1-9][0-9]*\)$/\1/g')}"	
		for var in $VAR; do	
			item3=$(echo ${var} | sed 's/^0*\([1-9][0-9]*\)$/\1/g')

			row=""

			if [ $[ $item % ($nObj * $nVar) ] -eq 0 ]; then
				row="$item1 &";
			else
				row=" &"
			fi

			if [ $[ $item %  $nVar] -eq 0 ]; then
				row="$row $item2 &";
			else
				row="$row &"
			fi
			
			row="$row $item3"

			for alg in $ALG; do
				pat="${pro}o${obj}v${var}_${alg}_front_*"
				num=$(ls output/$pat | wc -l)
				row="$row & $num"
			done

			row="$row \\\\"

			echo $row >> $ofs
			item=$[ $item + 1]
		done
	done
done

echo "\\bottomrule" >> $ofs
echo "\\end{tabular}" >> $ofs
echo "\\end{table*}" >> $ofs
fi

###################################################################################################################
################################### Table 2. Count of front(Pro. & obj. & Alg) ####################################
###################################################################################################################
if false; then
echo "\\begin{table*}" >> $ofs
echo "\\centering" >> $ofs
echo "\\caption{The number of runing of each alorithm for problems}" >> $ofs

echo "\\begin{tabular}{*{$[ $nAgl + 2]}{c}}" >> $ofs
echo "\\toprule" >> $ofs
echo "pro. & obj. & $(echo $ALG | sed 's/ / \& /g') \\\\" >> $ofs

item=0
for pro in $PRO; do
	echo "\\midrule" >> $ofs
	item1="\\multirow{$[ $nObj ]}*{$pro}"	
	for obj in $OBJ; do
		item2="$(echo ${obj} | sed 's/^0*\([1-9][0-9]*\)$/\1/g')"	

		row=""
		if [ $[ $item % $nObj ] -eq 0 ]; then
			row="$item1 &";
		else
			row=" &"
		fi

		row="$row $item2 "
			
		for alg in $ALG; do
			pat="${pro}o${obj}v*_${alg}_front_*"
			num=$(ls output/$pat | wc -l)
			row="$row & $num"
		done

		row="$row \\\\"
		echo $row >> $ofs
		item=$[ $item + 1]
	done
done

echo "\\bottomrule" >> $ofs
echo "\\end{tabular}" >> $ofs
echo "\\end{table*}" >> $ofs
fi
###################################################################################################################
########################################## Table 3. Count of front(Pro. & Alg) ####################################
###################################################################################################################
if true; then
echo "\\begin{table*}" >> $ofs
echo "\\centering" >> $ofs
echo "\\caption{The number of runing of each alorithm for problems}" >> $ofs

echo "\\begin{tabular}{*{$[ $nAgl + 1]}{c}}" >> $ofs
echo "\\toprule" >> $ofs
echo "pro. & $(echo $ALG | sed 's/ / \& /g') \\\\" >> $ofs

item=0
for pro in $PRO; do
	echo "\\midrule" >> $ofs
	row=$pro	
	for alg in $ALG; do
		pat="${pro}o*v*_${alg}_front_*"
		num=$(ls output/$pat | wc -l)
		row="$row & $num"
	done

	row="$row \\\\"
	echo $row >> $ofs
	item=$[ $item + 1]
done

echo "\\bottomrule" >> $ofs
echo "\\end{tabular}" >> $ofs
echo "\\end{table*}" >> $ofs
fi

###################################################################################################################
########################################## Table 1. HV with (Pro. Obj. Var. Alg) #################################
###################################################################################################################
if false; then
echo "\\begin{table*}" >> $ofs
echo "\\centering" >> $ofs
echo "\\caption{Average HV value obtained by alorithm for problems, best perfermance is marked by lightgray}" >> $ofs

echo "\\begin{tabular}{*{$[ $nAgl + 3]}{c}}" >> $ofs
echo "\\toprule" >> $ofs
echo "Pro. & Obj. & Var. & $(echo $ALG | sed 's/ / \& /g') \\\\" >> $ofs
echo "\\midrule" >> $ofs

item=0
for pro in $PRO; do
	item1="\\multirow{$[ $nObj * $nVar ]}*{$pro}"	
	for obj in $OBJ; do
		item2="\\multirow{$nVar}*{$(echo ${obj} | sed 's/^0*\([1-9][0-9]*\)$/\1/g')}"	
		for var in $VAR; do	
			item3=$(echo ${var} | sed 's/^0*\([1-9][0-9]*\)$/\1/g')

			row=""

			if [ $[ $item % ($nObj * $nVar) ] -eq 0 ]; then
				row="$item1 &";
			else
				row=" &"
			fi

			if [ $[ $item %  $nVar] -eq 0 ]; then
				row="$row $item2 &";
			else
				row="$row &"
			fi
			
			row="$row $item3"

			echo "A=[" > /tmp/row.m
			for alg in $ALG; do
				pat="${pro}o${obj}v${var}_${alg}_hv_*"
				echo "M=[" > /tmp/temp.m
				cat output/$pat >>  /tmp/temp.m
				echo "];" >> /tmp/temp.m
				echo "printf('%.4e', mean(M));">> /tmp/temp.m
				num=$(octave-cli /tmp/temp.m);
				echo "$num" >> /tmp/row.m
			done

			echo "];" >> /tmp/row.m
			echo "[C,I]=max(A);" >> /tmp/row.m
			echo "for i = 1:size(A,1)" >> /tmp/row.m
			echo "if i == I" >> /tmp/row.m
			echo "printf('& \\\\colorbox{lightgray}{%.4e}', A(i,1));" >> /tmp/row.m
			echo "else" >> /tmp/row.m
			echo "printf('& %.4e', A(i,1));" >> /tmp/row.m
			echo "end" >> /tmp/row.m
			echo "end" >> /tmp/row.m
			row="$row $(octave /tmp/row.m)"			

			row="$row \\\\"

			echo $row >> $ofs
			item=$[ $item + 1]
		done
	done
done

echo "\\bottomrule" >> $ofs
echo "\\end{tabular}" >> $ofs
echo "\\end{table*}" >> $ofs
fi



###################################################################################################################
######################################### Table 2. HV (Pro. & obj. & Alg) #########################################
###################################################################################################################
if false; then
echo "\\begin{table*}" >> $ofs
echo "\\centering" >> $ofs
echo "\\caption{Average HV value obtained by alorithm for problems, best perfermance is marked by lightgray}" >> $ofs

echo "\\begin{tabular}{*{$[ $nAgl + 2]}{c}}" >> $ofs
echo "\\toprule" >> $ofs
echo "pro. & obj. & $(echo $ALG | sed 's/ / \& /g') \\\\" >> $ofs

item=0
for pro in $PRO; do
	echo "\\midrule" >> $ofs
	item1="\\multirow{$[ $nObj ]}*{$pro}"	
	for obj in $OBJ; do
		item2="$(echo ${obj} | sed 's/^0*\([1-9][0-9]*\)$/\1/g')"	

		row=""
		if [ $[ $item % $nObj ] -eq 0 ]; then
			row="$item1 &";
		else
			row=" &"
		fi

		row="$row $item2 ";
			
		echo "A=[" > /tmp/row.m
		for alg in $ALG; do
			pat="${pro}o${obj}v*_${alg}_hv_*"
			echo "M=[" > /tmp/temp.m
			cat output/$pat >>  /tmp/temp.m
			echo "];" >> /tmp/temp.m
			echo "printf('%.4e', mean(M));">> /tmp/temp.m
			num=$(octave-cli /tmp/temp.m);
			echo "$num" >> /tmp/row.m
		done

		echo "];" >> /tmp/row.m
		echo "[C,I]=max(A);" >> /tmp/row.m
		echo "for i = 1:size(A,1)" >> /tmp/row.m
		echo "if i == I" >> /tmp/row.m
		echo "printf('& \\\\colorbox{lightgray}{%.4e}', A(i,1));" >> /tmp/row.m
		echo "else" >> /tmp/row.m
		echo "printf('& %.4e', A(i,1));" >> /tmp/row.m
		echo "end" >> /tmp/row.m
		echo "end" >> /tmp/row.m
		row="$row $(octave /tmp/row.m)"			

		row="$row \\\\"

		echo $row >> $ofs
		item=$[ $item + 1]
	done
done

echo "\\bottomrule" >> $ofs
echo "\\end{tabular}" >> $ofs
echo "\\end{table*}" >> $ofs
fi

###################################################################################################################
################################################ Table 3. HV (Pro. & Alg) #########################################
###################################################################################################################
if false; then
echo "\\begin{table*}" >> $ofs
echo "\\centering" >> $ofs
echo "\\caption{Average HV value obtained by alorithm for problems, best perfermance is marked by lightgray}" >> $ofs

echo "\\begin{tabular}{*{$[ $nAgl + 1]}{c}}" >> $ofs
echo "\\toprule" >> $ofs
echo "pro. & $(echo $ALG | sed 's/ / \& /g') \\\\" >> $ofs

item=0
for pro in $PRO; do
	echo "\\midrule" >> $ofs

	row=$pro
			
	echo "A=[" > /tmp/row.m
	for alg in $ALG; do
		pat="${pro}o*v*_${alg}_hv_*"
		echo "M=[" > /tmp/temp.m
		cat output/$pat >>  /tmp/temp.m
		echo "];" >> /tmp/temp.m
		echo "printf('%.4e', mean(M));">> /tmp/temp.m
		num=$(octave-cli /tmp/temp.m);
		echo "$num" >> /tmp/row.m
	done

	echo "];" >> /tmp/row.m
	echo "[C,I]=max(A);" >> /tmp/row.m
	echo "for i = 1:size(A,1)" >> /tmp/row.m
	echo "if i == I" >> /tmp/row.m
	echo "printf('& \\\\colorbox{lightgray}{%.4e}', A(i,1));" >> /tmp/row.m
	echo "else" >> /tmp/row.m
	echo "printf('& %.4e', A(i,1));" >> /tmp/row.m
	echo "end" >> /tmp/row.m
	echo "end" >> /tmp/row.m
	row="$row $(octave /tmp/row.m)"			

	row="$row \\\\"

	echo $row >> $ofs
	item=$[ $item + 1]
done

echo "\\bottomrule" >> $ofs
echo "\\end{tabular}" >> $ofs
echo "\\end{table*}" >> $ofs
fi

###################################################################################################################
######################################## Table 1. IGD (Pro. Obj. Var. Alg) ########################################
###################################################################################################################
if false; then
echo "\\begin{table*}" >> $ofs
echo "\\centering" >> $ofs
echo "\\caption{Average IGD values obtained by alorithms for problems, the best perfermance is marked in lightgray}" >> $ofs

echo "\\begin{tabular}{*{$[ $nAgl + 3]}{c}}" >> $ofs
echo "\\toprule" >> $ofs
echo "Pro. & Obj. & Var. & $(echo $ALG | sed 's/ / \& /g') \\\\" >> $ofs
echo "\\midrule" >> $ofs

item=0
for pro in $PRO; do
	item1="\\multirow{$[ $nObj * $nVar ]}*{$pro}"	
	for obj in $OBJ; do
		item2="\\multirow{$nVar}*{$(echo ${obj} | sed 's/^0*\([1-9][0-9]*\)$/\1/g')}"	
		for var in $VAR; do	
			item3=$(echo ${var} | sed 's/^0*\([1-9][0-9]*\)$/\1/g')

			row=""

			if [ $[ $item % ($nObj * $nVar) ] -eq 0 ]; then
				row="$item1 &";
			else
				row=" &"
			fi

			if [ $[ $item %  $nVar] -eq 0 ]; then
				row="$row $item2 &";
			else
				row="$row &"
			fi
			
			row="$row $item3"

			echo "A=[" > /tmp/row.m
			for alg in $ALG; do
				pat="${pro}o${obj}v${var}_${alg}_igd_*"
				echo "M=[" > /tmp/temp.m
				cat output/$pat >>  /tmp/temp.m
				echo "];" >> /tmp/temp.m
				echo "printf('%.4e', mean(M));">> /tmp/temp.m
				num=$(octave-cli /tmp/temp.m);
				echo "$num" >> /tmp/row.m
			done

			echo "];" >> /tmp/row.m
			echo "[C,I]=min(A);" >> /tmp/row.m
			echo "for i = 1:size(A,1)" >> /tmp/row.m
			echo "if i == I" >> /tmp/row.m
			echo "printf('& \\\\colorbox{lightgray}{%.4e}', A(i,1));" >> /tmp/row.m
			echo "else" >> /tmp/row.m
			echo "printf('& %.4e', A(i,1));" >> /tmp/row.m
			echo "end" >> /tmp/row.m
			echo "end" >> /tmp/row.m
			row="$row $(octave /tmp/row.m)"			

			row="$row \\\\"

			echo $row >> $ofs
			item=$[ $item + 1]
		done
	done
done

echo "\\bottomrule" >> $ofs
echo "\\end{tabular}" >> $ofs
echo "\\end{table*}" >> $ofs
fi


###################################################################################################################
##################################### Table 2. of IGD (Pro. & obj. & Alg) #########################################
###################################################################################################################
if true; then
echo "\\begin{table*}" >> $ofs
echo "\\centering" >> $ofs
echo "\\caption{Average IGD values obtained by alorithms for problems, the best perfermance is marked in lightgray}" >> $ofs

echo "\\begin{tabular}{*{$[ $nAgl + 2]}{c}}" >> $ofs
echo "\\toprule" >> $ofs
echo "pro. & obj. & $(echo $ALG | sed 's/ / \& /g') \\\\" >> $ofs

item=0
for pro in $PRO; do
	echo "\\midrule" >> $ofs
	item1="\\multirow{$[ $nObj ]}*{$pro}"	
	for obj in $OBJ; do
		item2="$(echo ${obj} | sed 's/^0*\([1-9][0-9]*\)$/\1/g')"	

		row=""
		if [ $[ $item % $nObj ] -eq 0 ]; then
			row="$item1 &";
		else
			row=" &"
		fi

		row="$row $item2 ";
			
		echo "A=[" > /tmp/row.m
		for alg in $ALG; do
			pat="${pro}o${obj}v*_${alg}_igd_*"
			echo "M=[" > /tmp/temp.m
			cat output/$pat >>  /tmp/temp.m
			echo "];" >> /tmp/temp.m
			echo "printf('%.4e', mean(M));">> /tmp/temp.m
			num=$(octave-cli /tmp/temp.m);
			echo "$num" >> /tmp/row.m
		done

		echo "];" >> /tmp/row.m
		echo "[C,I]=min(A);" >> /tmp/row.m
		echo "for i = 1:size(A,1)" >> /tmp/row.m
		echo "if i == I" >> /tmp/row.m
		echo "printf('& \\\\colorbox{lightgray}{%.4e}', A(i,1));" >> /tmp/row.m
		echo "else" >> /tmp/row.m
		echo "printf('& %.4e', A(i,1));" >> /tmp/row.m
		echo "end" >> /tmp/row.m
		echo "end" >> /tmp/row.m
		row="$row $(octave /tmp/row.m)"			

		row="$row \\\\"

		echo $row >> $ofs
		item=$[ $item + 1]
	done
done

echo "\\bottomrule" >> $ofs
echo "\\end{tabular}" >> $ofs
echo "\\end{table*}" >> $ofs
fi

###################################################################################################################
######################################## Table 1. I_epsilon (Pro. Obj. Var. Alg) ##################################
###################################################################################################################
if false; then
echo "\\begin{table*}" >> $ofs
echo "\\centering" >> $ofs
echo "\\caption{Average \$I_{\epsilon\text{+}}\$ value obtained by alorithm for problems, best perfermance is marked by lightgray}" >> $ofs

echo "\\begin{tabular}{*{$[ $nAgl + 3]}{c}}" >> $ofs
echo "\\toprule" >> $ofs
echo "Pro. & Obj. & Var. & $(echo $ALG | sed 's/ / \& /g') \\\\" >> $ofs
echo "\\midrule" >> $ofs

item=0
for pro in $PRO; do
	item1="\\multirow{$[ $nObj * $nVar ]}*{$pro}"	
	for obj in $OBJ; do
		item2="\\multirow{$nVar}*{$(echo ${obj} | sed 's/^0*\([1-9][0-9]*\)$/\1/g')}"	
		for var in $VAR; do	
			item3=$(echo ${var} | sed 's/^0*\([1-9][0-9]*\)$/\1/g')

			row=""

			if [ $[ $item % ($nObj * $nVar) ] -eq 0 ]; then
				row="$item1 &";
			else
				row=" &"
			fi

			if [ $[ $item %  $nVar] -eq 0 ]; then
				row="$row $item2 &";
			else
				row="$row &"
			fi
			
			row="$row $item3"

			echo "A=[" > /tmp/row.m
			for alg in $ALG; do
				pat="${pro}o${obj}v${var}_${alg}_epsilon_*"
				echo "M=[" > /tmp/temp.m
				cat output/$pat >>  /tmp/temp.m
				echo "];" >> /tmp/temp.m
				echo "printf('%.4e', mean(M));">> /tmp/temp.m
				num=$(octave-cli /tmp/temp.m);
				echo "$num" >> /tmp/row.m
			done

			echo "];" >> /tmp/row.m
			echo "[C,I]=max(A);" >> /tmp/row.m
			echo "for i = 1:size(A,1)" >> /tmp/row.m
			echo "if i == I" >> /tmp/row.m
			echo "printf('& \\\\colorbox{lightgray}{%.4e}', A(i,1));" >> /tmp/row.m
			echo "else" >> /tmp/row.m
			echo "printf('& %.4e', A(i,1));" >> /tmp/row.m
			echo "end" >> /tmp/row.m
			echo "end" >> /tmp/row.m
			row="$row $(octave /tmp/row.m)"			

			row="$row \\\\"

			echo $row >> $ofs
			item=$[ $item + 1]
		done
	done
done

echo "\\bottomrule" >> $ofs
echo "\\end{tabular}" >> $ofs
echo "\\end{table*}" >> $ofs
fi

###################################################################################################################
################################# Table 2. of I_epsilon(Pro. & obj. & Alg) ##################################
###################################################################################################################
if false; then
echo "\\begin{table*}" >> $ofs
echo "\\centering" >> $ofs
echo "\\caption{Average \$I_{\epsilon\text{+}}\$ value obtained by alorithm for problems, best perfermance is marked by lightgray}" >> $ofs

echo "\\begin{tabular}{*{$[ $nAgl + 2]}{c}}" >> $ofs
echo "\\toprule" >> $ofs
echo "pro. & obj. & $(echo $ALG | sed 's/ / \& /g') \\\\" >> $ofs

item=0
for pro in $PRO; do
	echo "\\midrule" >> $ofs
	item1="\\multirow{$[ $nObj ]}*{$pro}"	
	for obj in $OBJ; do
		item2="$(echo ${obj} | sed 's/^0*\([1-9][0-9]*\)$/\1/g')"	

		row=""
		if [ $[ $item % $nObj ] -eq 0 ]; then
			row="$item1 &";
		else
			row=" &"
		fi

		row="$row $item2 ";
			
		echo "A=[" > /tmp/row.m
		for alg in $ALG; do
			pat="${pro}o${obj}v*_${alg}_epsilon_*"
			echo "M=[" > /tmp/temp.m
			cat output/$pat >>  /tmp/temp.m
			echo "];" >> /tmp/temp.m
			echo "printf('%.4e', mean(M));">> /tmp/temp.m
			num=$(octave-cli /tmp/temp.m);
			echo "$num" >> /tmp/row.m
		done

		echo "];" >> /tmp/row.m
		echo "[C,I]=min(A);" >> /tmp/row.m
		echo "for i = 1:size(A,1)" >> /tmp/row.m
		echo "if i == I" >> /tmp/row.m
		echo "printf('& \\\\colorbox{lightgray}{%.4e}', A(i,1));" >> /tmp/row.m
		echo "else" >> /tmp/row.m
		echo "printf('& %.4e', A(i,1));" >> /tmp/row.m
		echo "end" >> /tmp/row.m
		echo "end" >> /tmp/row.m
		row="$row $(octave /tmp/row.m)"			

		row="$row \\\\"

		echo $row >> $ofs
		item=$[ $item + 1]
	done
done

echo "\\bottomrule" >> $ofs
echo "\\end{tabular}" >> $ofs
echo "\\end{table*}" >> $ofs
fi

echo "\\end{document}" >> $ofs

cd latex 
xelatex ${ofs##*/}
open -a safari table.pdf
