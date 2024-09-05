#!/bin/bash

# input: PRO, OBJ, VAR, ALG, RUN
source ./Args_for_shell.sh

# the title of table
outfile="./tmp/table-of-group"

# head of document
echo "\\documentclass{IEEEtran}" > $outfile.tex
echo "\\input{/Users/fengyin/Documents/TeX/package.tex}" >> $outfile.tex
echo "\\begin{document}" >> $outfile.tex

# 
for alg in ${ALG}; do
echo "\\begin{table*}" >> $outfile.tex
echo "\\centering" >> $outfile.tex
echo "\\caption{Grouping of $alg for each running.}" >> $outfile.tex
echo "\\scalebox{0.1}{" >> $outfile.tex

# the head of table
echo "\\begin{tabular}{ccc|*{${RUN}}{c}}" >> $outfile.tex
echo "\\toprule" >> $outfile.tex
echo "Pro. & Obj. & Var. & $(echo $(seq 1 ${RUN}) | sed 's/ / \& /g') \\\\" >> $outfile.tex

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
		h5=$h4/grp
		h6=$h5/RUN$(printf '%03d' $run)

		if [  -d $h6 ]; then
			num=$(ls $h6 | wc -l)
		else
			num=0
		fi	

		if [ $num -gt 0 ]; then
			flag=$(cat $h6/* | tail -n 1)
			if [ $flag -ne 1 ]; then
				flag="\\colorbox{red}{0}"
			fi
		else 
			flag="\\colorbox{green}{0}"
		fi	
		line="$line & $flag"
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
