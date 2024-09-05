#!/bin/bash

# input: PRO, OBJ, VAR, ALG, RUN
source ./Args_for_shell.sh

# clean lost-cases
cat /dev/null > ./tmp/lost-cases

# the title of table
outfile="./tmp/table-of-obj"

# head of document
echo "\\documentclass{IEEEtran}" > $outfile.tex
echo "\\input{/Users/fengyin/Documents/TeX/package.tex}" >> $outfile.tex
echo "\\begin{document}" >> $outfile.tex

# 
for alg in ${ALG}; do
echo "\\begin{table*}" >> $outfile.tex
echo "\\centering" >> $outfile.tex
echo "\\caption{Number of Objective File on $alg for Each Running.}" >> $outfile.tex
echo "\\scalebox{0.3}{" >> $outfile.tex

# the head of table
echo "\\begin{tabular}{ccc|*{${RUN}}{c}}" >> $outfile.tex
echo "\\toprule" >> $outfile.tex
echo "Pro. & Obj. & VAR & $(echo $(seq 1 ${RUN}) | sed 's/ / \& /g') \\\\" >> $outfile.tex

for pro in ${PRO}; do
for obj in ${OBJ}; do 			
echo "\\midrule" >> $outfile.tex
for var in ${VAR}; do
	line="$pro & $obj & $var"

	for run in $(seq 1 ${RUN}); do
		# the body of table
		root="./tmp/OUTPUT"		
		h1=$root/$pro
		h2=$h1/OBJ$(printf '%02d' $obj)
		h3=$h2/VAR$(printf '%05d' $var)
		h4=$h3/$alg
		h5=$h4/obj
		h6=$h5/RUN$(printf '%03d' $run)

		if [  -d $h6 ]; then
			num=$(ls $h6 | wc -l)
		else
			num=0
		fi	

		# get lost cases
		if [ $num -eq 0 ]; then
			if [ $obj -eq 2 ]; then
				echo $alg $pro $obj $var 100 ${var}0000 $run >> ./tmp/lost-cases
			elif [ $obj -eq 3 ]; then
				echo $alg $pro $obj $var 105 ${var}0000 $run >> ./tmp/lost-cases
			fi
		fi

		# color data
		if [ $num -lt 21 ]; then
			num="\\colorbox{red}{$num}"
		elif [ $num -gt 21 ]; then
			num="\\colorbox{green}{$num}"
		fi

		line="$line & $num"
	done
	echo "$line \\\\">> $outfile.tex
done
done
done
echo "\\bottomrule" >> $outfile.tex
echo "\\end{tabular}}" >> $outfile.tex
echo "\\end{table*}" >> $outfile.tex
done
echo "\\end{document}" >> $outfile.tex
