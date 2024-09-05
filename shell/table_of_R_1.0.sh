#!/bin/bash

# input: PRO, OBJ, VAR, ALG, RUN
source ./Args_for_shell.sh

# the title of table
outfile="./tmp/table-of-R"

# head of document
echo "\\documentclass{IEEEtran}" > $outfile.tex
echo "\\input{/Users/fengyin/Documents/TeX/package.tex}" >> $outfile.tex
echo "\\begin{document}" >> $outfile.tex



# the body of table
for pro in ${PRO}; do
for obj in ${OBJ}; do 			
for var in ${VAR}; do
for alg in ${ALG}; do
for run in $(seq 1 $RUN); do
	root="./tmp/OUTPUT"		
	h1=$root/$pro
	h2=$h1/OBJ$(printf '%02d' $obj)
	h3=$h2/VAR$(printf '%05d' $var)
	h4=$h3/$alg
	h5=$h4/pv
	h6=$h5/RUN$(printf '%03d' $run)

	if [  -d $h6 ]; then
		pv=$(cat $(ls $h6/* | tail -n 1 ))
	else
		echo "ERROR: Directory $h6 does not exits."
		echo "Maybe forget to make the tree."
		exit
	fi	
	# begin table
	echo "\\begin{table*}" >> $outfile.tex
	echo "\\centering" >> $outfile.tex
	echo "\\caption{Relationships between variables On $pro with $obj objectives and $var variables, PV: $pv.}" >> $outfile.tex

	# table
	echo "\\scalebox{0.3}{" >> $outfile.tex
	echo "\\begin{tabular}{c*{$var}{c}}" >> $outfile.tex
	echo "\\toprule" >> $outfile.tex
	echo "VAR. & $(echo $(seq 0 $[ $var - 1] ) | sed 's/ / \& /g') \\\\" >> $outfile.tex

	root="./tmp/OUTPUT"		
	h1=$root/$pro
	h2=$h1/OBJ$(printf '%02d' $obj)
	h3=$h2/VAR$(printf '%05d' $var)
	h4=$h3/$alg
	h5=$h4/R
	h6=$h5/RUN$(printf '%03d' $run)

	matscript=/tmp/mat$$$$.m
	touch $matscript
	if [  -d $h6 ]; then
		echo "R=[" >> $matscript
		cat $(ls $h6/* | tail -n 1 ) >> $matscript
		echo "];" >> $matscript
	else
		echo "ERROR: Directory $h6 does not exits."
		echo "Maybe forget to make the tree."
		exit
	fi	

	echo "for i=1:size(R,1)" >> $matscript
		echo "printf('%d', i - 1);" >> $matscript
		echo "for j=1:size(R, 2)" >> $matscript
			echo "if R(i, j) == 7" >> $matscript
				echo "printf(', \\\\colorbox{green}{%d}',  R(i,j));" >> $matscript
			echo "elseif R(i, j) == 3" >> $matscript
				echo "printf(', \\\\colorbox{magenta}{%d}',  R(i,j));" >> $matscript
			echo "elseif R(i, j) == 2" >> $matscript
				echo "printf(', \\\\colorbox{cyan}{%d}',  R(i,j));" >> $matscript
			echo "else" >> $matscript
				echo "printf(', \\\\colorbox{yellow}{%d}',  R(i,j));" >> $matscript
			echo "end" >> $matscript
		echo "end" >> $matscript
		echo "printf('\\\\\\\\ \n');" >> $matscript
	echo "end" >> $matscript

	# run matlab script
	v=$(echo $(octave-cli $matscript) | sed 's/,/ \& /g')
	rm $matscript

	echo "\\midrule" >> $outfile.tex
	echo $v  >> $outfile.tex
	echo "\\bottomrule" >> $outfile.tex
	echo "\\end{tabular}}" >> $outfile.tex

	# the table
	echo "\\scalebox{0.3}{" >> $outfile.tex
	echo "\\begin{tabular}{c*{$var}{c}}" >> $outfile.tex
	echo "\\toprule" >> $outfile.tex
	echo "VAR. & $(echo $(seq 0 $[ $var - 1] ) | sed 's/ / \& /g') \\\\" >> $outfile.tex

	root="./tmp/OUTPUT"		
	h1=$root/$pro
	h2=$h1/OBJ$(printf '%02d' $obj)
	h3=$h2/VAR$(printf '%05d' $var)
	h4=$h3/$alg
	h5=$h4/theta
	h6=$h5/RUN$(printf '%03d' $run)

	matscript=/tmp/mat$$$$.m
	touch $matscript
	if [  -d $h6 ]; then
		echo "R=[" >> $matscript
		cat $(ls $h6/* | tail -n 1 ) >> $matscript
		echo "];" >> $matscript
	else
		echo "ERROR: Directory $h6 does not exits."
		echo "Maybe forget to make the tree."
		exit
	fi	

	echo "for i=1:size(R,1)" >> $matscript
		echo "printf('%d', i - 1);" >> $matscript
		echo "for j=1:size(R, 2)" >> $matscript
			echo "if R(i, j) > 0" >> $matscript
				echo "printf(', \\\\colorbox{green}{%d}',  R(i,j));" >> $matscript
			echo "else" >> $matscript
				echo "printf(', %d', R(i,j));" >> $matscript
			echo "end" >> $matscript
		echo "end" >> $matscript
		echo "printf('\\\\\\\\ \n');" >> $matscript
	echo "end" >> $matscript

	# run matlab script
	v=$(echo $(octave-cli $matscript) | sed 's/,/ \& /g')
	rm $matscript

	echo "\\midrule" >> $outfile.tex
	echo $v  >> $outfile.tex
	echo "\\bottomrule" >> $outfile.tex
	echo "\\end{tabular}}" >> $outfile.tex
	echo "\\end{table*}" >> $outfile.tex
done
done
done
done
done
echo "\\end{document}" >> $outfile.tex
