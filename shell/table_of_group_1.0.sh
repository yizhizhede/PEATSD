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
for var in ${VAR}; do
echo "\\begin{table*}" >> $outfile.tex
echo "\\centering" >> $outfile.tex
echo "\\caption{Groups by $alg with $var decision variables.}" >> $outfile.tex
echo "\\scalebox{0.2}{" >> $outfile.tex

# the head of table
echo "\\begin{tabular}{ccc|*{${RUN}}{c}}" >> $outfile.tex
echo "\\toprule" >> $outfile.tex
echo "Pro. & Obj. & Var. & $(echo $(seq 1 ${RUN}) | sed 's/ / \& /g') \\\\" >> $outfile.tex

for pro in ${PRO}; do
for obj in ${OBJ}; do 			
	echo "\\midrule" >> $outfile.tex
	line="$pro & $obj & $var"

	tmpfile=/tmp/tmpfile$$$$
	touch $tmpfile
	for run in $(seq 1 ${RUN}); do
		# the body of table
		root="./tmp/OUTPUT"		
		h1=$root/$pro
		h2=$h1/OBJ$(printf '%02d' $obj)
		h3=$h2/VAR$(printf '%05d' $var)
		h4=$h3/$alg
		h5=$h4/I
		h6=$h5/RUN$(printf '%03d' $run)

		if [  -d $h6 ]; then
			echo -n " & " >> $tmpfile
			cat ${h6}/$(ls ${h6} | tail -n 1) | grep -n 0 | while read buff; do
				echo -n "${buff%%:*} " >> $tmpfile
			done
		else
			echo "ERROR: Directory $h6 does not exits."
			echo "Maybe forget to make the tree."
			exit
		fi	
	done
	line="$line $(cat $tmpfile)"
	echo "$line \\\\">> $outfile.tex
	rm $tmpfile
done
done
echo "\\bottomrule" >> $outfile.tex
echo "\\end{tabular}}" >> $outfile.tex
echo "\\end{table*}" >> $outfile.tex
done
done
echo "\\end{document}" >> $outfile.tex
