#!/bin/bash

# input: PRO, OBJ, VAR, ALG, RUN
source ./Args_for_shell.sh

# the title of table
outfile="./tmp/table-of-rank-hv"

# head of document
echo "\\documentclass{IEEEtran}" > $outfile.tex
echo "\\input{/Users/fengyin/Documents/TeX/package.tex}" >> $outfile.tex
echo "\\begin{document}" >> $outfile.tex

# begin table
echo "\\begin{table*}" >> $outfile.tex
echo "\\centering" >> $outfile.tex
echo "\\caption{Rank of Algorithms on HV}" >> $outfile.tex
echo "\\scalebox{1.0}{" >> $outfile.tex

# the head of table
echo "\\begin{tabular}{c*{$(echo $ALG | wc -w )}{c}}" >> $outfile.tex
echo "\\toprule" >> $outfile.tex
echo "Rank & $(echo $ALG | sed 's/ / \& /g') \\\\" >> $outfile.tex

# matlab script
matscript=/tmp/mat$$$$.m
touch $matscript
echo "M=[];" > $matscript

# the body of table
for pro in ${PRO}; do
for obj in ${OBJ}; do 			

for var in ${VAR}; do
	for alg in ${ALG}; do
		echo "$alg=[];" >> $matscript
		for run in $(seq 1 $RUN); do
			root="./tmp/OUTPUT"		
			h1=$root/$pro
			h2=$h1/OBJ$(printf '%02d' $obj)
			h3=$h2/VAR$(printf '%05d' $var)
			h4=$h3/$alg
			h5=$h4/hv
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

	# HV Matrix
	echo "A=[];" >> $matscript
	for alg in $ALG; do
		echo "A=[A, $alg];" >> $matscript
	done
	if [ $RUN -le 1 ]; then
		echo "A=[A;A];" >> $matscript
	fi
	echo "M=[M; mean(A)];" >> $matscript
done
done
done

echo "[~,~,rk]=friedman(-M);" >> $matscript
echo "rk=rk.meanranks;" >> $matscript
echo "dlmwrite('/tmp/rank', rk);" >> $matscript
echo "exit;" >> $matscript

# run matlab script
cat $matscript | matlab > /dev/null
rm $matscript

# extract result of matlab
line=$(cat /tmp/rank | sed 's/,/ \& /g')
line="Avarage Rank & $line"
echo "\\midrule" >> $outfile.tex
echo "$line\\\\"  >> $outfile.tex

# matlab scription
echo "M=dlmread ('/tmp/rank');" > $matscript
echo "[~, I]=sort (M, 2);" >> $matscript
echo "R=[];" >> $matscript
echo "for i=1:size(M,2)" >> $matscript
echo "R=[R, find(I == i)];" >> $matscript
echo "end" >> $matscript
echo "dlmwrite('/tmp/finalRank', R);" >> $matscript
echo "exit;" >> $matscript

# run matlab script
cat $matscript | matlab > /dev/null
rm $matscript

# extract result of matlab
line=$(cat /tmp/finalRank | sed 's/,/ \& /g')
line="Final Rank & $line"
echo "\\midrule" >> $outfile.tex
echo "$line\\\\"  >> $outfile.tex

echo "\\bottomrule" >> $outfile.tex
echo "\\end{tabular}}" >> $outfile.tex
echo "\\end{table*}" >> $outfile.tex
echo "\\end{document}" >> $outfile.tex
