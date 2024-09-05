#!/bin/bash

OBJ="OBJ02 OBJ03"			# 1. set the number of objective into {2, 3, 4, 5}. 
ALG="NSGAII NSEA"			# 2. a set of algorithms. 
# ALG="NSGAII"				# 2. a set of algorithms. 

for obj in ${OBJ}; do 			# each objective is related with one table, respectively.
	# the title of table
	outfile="./tmp/table-igd-${obj}"
	echo "\\documentclass{IEEEtran}" > $outfile.tex
	echo "\\input{/Users/fengyin/Documents/TeX/package.tex}" >> $outfile.tex
	echo "\\begin{document}" >> $outfile.tex
	echo "\\begin{table*}" >> $outfile.tex
	echo "\\centering" >> $outfile.tex
	echo "\\caption{The Average (the standard variance) of IGD value obtained by ${ALG// /,} on the problems with ${obj##*0} objectives. The best perfermance is marked by lightgray.}" >> $outfile.tex
	echo "\\scalebox{0.3}{" >> $outfile.tex
	# the head of table
	echo "\\begin{tabular}{*{$[ $(echo $ALG | wc -w ) + 2]}{c}}" >> $outfile.tex
	echo "\\toprule" >> $outfile.tex
	echo "Pro. & Var. & $(echo $ALG | sed 's/ / \& /g') \\\\" >> $outfile.tex

# the body of table
h0="./tmp/OUTPUT"		# h0 indicates the root 
for h1 in ${h0}/*; do 		# h1 has arrived at the title of problem.
	echo "\\midrule" >> $outfile.tex	# There should exist a line before every problems
	h2=${h1}/${obj} 	# h2 has arrived at the number of objective. 
	if [ ! -d $h2 ]; then	# if h2 doesn't exit, continue.
		continue
	fi
	C1=${h1##*/}		# The colume 1: the title of problem
	nrow=0			# The rank of row
for h3  in ${h2}/*; do		# h3 has arrived at the number of variables
	nrow=$[ $nrow + 1 ]	# The rank of row
	C2=$( echo ${h3##*/} | sed 's/^VAR0*\(.*\)$/\1/g')	# The colume 2: The number of variables

# temple file of a matlab script
tmp="./tmp/tmp.m"
cat /dev/null > $tmp
echo "D=[];" >> $tmp
nalg=0
for alg in $ALG; do
	nalg=$[ $nalg + 1 ]	# The number of algorithms
	h4="${h3}/${alg}"	# h4 has arrived at the title of algorithm
	h5="${h4}/igd"		# h5 has arrived at the type of file
	
	# generate the matlab script
	i=0;
	for h6 in ${h5}/*; do	# h6 has arrived at the number of runing
		i=$[ $i + 1 ]
		echo "R${nalg}${i} = [" >> $tmp
		cat ${h6}/* >> $tmp
		echo "];" >> $tmp
	done

	echo "R${nalg}=[];" >> $tmp
	while [ $i -gt 0 ]; do	
		echo "R${nalg}=[R${nalg}; R${nalg}$i(end, 1)];" >> $tmp
		i=$[ $i - 1 ]
	done
	echo "D=[D, R${nalg}];" >> $tmp
done
	# mean and standard variance
	echo "if 1 == size(D, 1)" >> $tmp
	echo "A=[D; D<0];" >> $tmp
	echo "else" >> $tmp
	echo "A=[mean(D); std(D)];" >> $tmp
	echo "end" >> $tmp
	echo "A=A';" >> $tmp
	echo "[M, I]=min(A);" >> $tmp
	echo "for i=1:size(A,1)" >> $tmp
	echo "if i == I(1,1)" >> $tmp
	echo "printf('\\\\colorbox{lightgray}{%.4e(%.2e)},', A(i, 1), A(i,2));" >> $tmp
	echo "else" >> $tmp
	echo "printf('%.4e(%.2e),', A(i, 1), A(i, 2));" >> $tmp
	echo "end" >> $tmp
	echo "end" >> $tmp

	# non-paramter check
	t="${h3//\//_}_igd.csv"
	echo "fp=fopen('./tmp/${t:13}', 'w');" >> $tmp
	echo "fprintf(fp, 'No.,');" >> $tmp
	echo "fprintf(fp, '${ALG// /,}\n');" >> $tmp
	echo "for i=1:size(D, 1)" >> $tmp
	echo "fprintf(fp, '%d', i)" >> $tmp
	echo "for j=1:size(D, 2)" >> $tmp
	echo "fprintf(fp, ',%.16f', D(i,j))" >> $tmp
	echo "end" >> $tmp
	echo "fprintf(fp, '\n')" >> $tmp
	echo "end" >> $tmp

	# perform the matlab script	
	v=$(octave-cli $tmp)
	v=${v//,/&}
	C3=${v%&*}	# The colume 3, 4, ...

	# 	
	if [ $nrow -eq 1 ]; then
		line="$C1 & $C2 & $C3 \\\\"
	else

		line="   & $C2 & $C3 \\\\"
	fi
	echo "$line" >> $outfile.tex
done
done
echo "\\bottomrule" >> $outfile.tex
echo "\\end{tabular}}" >> $outfile.tex
echo "\\end{table*}" >> $outfile.tex
echo "\\end{document}" >> $outfile.tex
done
