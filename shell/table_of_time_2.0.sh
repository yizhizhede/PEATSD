#!/bin/bash

# input: PRO, OBJ, VAR, ALG, RUN
source ./Args_for_shell.sh

# the title of table
outfile="./tmp/table-of-time"

# head of document
echo "\\documentclass{IEEEtran}" > $outfile.tex
echo "\\input{/Users/fengyin/Documents/TeX/package.tex}" >> $outfile.tex
echo "\\begin{document}" >> $outfile.tex

# begin table
echo "\\begin{table*}" >> $outfile.tex
echo "\\centering" >> $outfile.tex
echo "\\caption{Running time (h) of Algorithms}" >> $outfile.tex
echo "\\scalebox{0.3}{" >> $outfile.tex

# the head of table
echo "\\begin{tabular}{ccc*{$(echo $ALG | wc -w )}{c}}" >> $outfile.tex
echo "\\toprule" >> $outfile.tex
echo "Pro. & Obj. & Var. & $(echo $ALG | sed 's/ / \& /g') \\\\" >> $outfile.tex

# the body of table
for pro in ${PRO}; do
for obj in ${OBJ}; do 			
echo "\\midrule" >> $outfile.tex
for var in ${VAR}; do
	line="$pro & $obj & $var"

	# matlab script	for getting a row of data
	matscript=/tmp/mat$$$$.m
	touch $matscript

	for alg in ${ALG}; do
		echo "$alg=[];" >> $matscript
		for run in $(seq 1 $RUN); do
			root="./tmp/OUTPUT"		
			h1=$root/$pro
			h2=$h1/OBJ$(printf '%02d' $obj)
			h3=$h2/VAR$(printf '%05d' $var)
			h4=$h3/$alg
			h5=$h4/time
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

			echo "$alg=[$alg; $alg$run(end,end)];" >> $matscript
		done
	done

	echo "A=[];" >> $matscript
	for alg in $ALG; do
		echo "A=[A, $alg];" >> $matscript
	done
	if [ $RUN -le 1 ]; then
		echo "A=[A;A];" >> $matscript
	fi
	echo "M=mean(A);" >> $matscript
	echo "[V,I]=min(M);" >> $matscript
#	echo "M=M./3600;" >> $matscript
	echo "for i=1:size(M,2)" >> $matscript
	echo "if i == I" >> $matscript
	echo "printf(',\\\\colorbox{lightgray}{%.3f}',  M(1,i));" >> $matscript
	echo "else" >> $matscript
	echo "printf(',%.3f',  M(1,i));" >> $matscript
	echo "end" >> $matscript
	echo "end" >> $matscript
	
	# run matlab script
	v=$(echo $(octave-cli $matscript) | sed 's/,/ \& /g')
	rm $matscript

	line="$line $v \\\\"
	echo $line  >> $outfile.tex
done
done
done
echo "\\bottomrule" >> $outfile.tex
echo "\\end{tabular}}" >> $outfile.tex
echo "\\end{table*}" >> $outfile.tex
echo "\\end{document}" >> $outfile.tex
