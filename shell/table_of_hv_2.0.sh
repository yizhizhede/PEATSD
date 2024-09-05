#!/bin/bash

# input: PRO, OBJ, VAR, ALG, RUN
source ./Args_for_shell.sh

# the title of table
outfile="./tmp/table-of-hv"

# head of document
echo "\\documentclass{IEEEtran}" > $outfile.tex
echo "\\input{/Users/fengyin/Documents/TeX/package.tex}" >> $outfile.tex
echo "\\begin{document}" >> $outfile.tex

# begin table
echo "\\begin{table*}" >> $outfile.tex
echo "\\centering" >> $outfile.tex
echo "\\caption{HV of Algorithms}" >> $outfile.tex
echo "\\scalebox{0.3}{" >> $outfile.tex
echo "\\setlength{\\tabcolsep}{1.0mm}{" >> $outfile.tex

# the head of table
echo "\\begin{tabular}{ccc*{$(echo $ALG | wc -w )}{c}}" >> $outfile.tex
echo "\\toprule" >> $outfile.tex
echo "Pro. & Obj. & Var. & $(echo $ALG | sed 's/ / \& /g') \\\\" >> $outfile.tex

# the body of table
for pro in ${PRO}; do
for obj in ${OBJ}; do 			
echo "\\specialrule{0em}{0pt}{0pt}" >> $outfile.tex
echo "\\midrule" >> $outfile.tex
echo "\\specialrule{0em}{0pt}{0pt}" >> $outfile.tex
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

	# non-parameter check
	echo "fp=fopen('./tmp/${pro}_$(printf '%02d' $obj)_$(printf '%05d' $var).csv', 'w');" >> $matscript

	# head of table
	echo "fprintf(fp, 'NO');" >> $matscript
	for alg in $ALG; do
		echo "fprintf(fp, ', %s',  '$alg');" >> $matscript
	done
	echo "fprintf(fp, '\n');" >> $matscript
	
	# body of table
	for i in $(seq 1 $RUN); do 
		echo "fprintf(fp, '%d', $i);" >> $matscript
		for alg in $ALG; do
			echo "fprintf(fp, ', %.16f',  $alg($i, 1));" >> $matscript
		done
		echo "fprintf(fp, '\n');" >> $matscript
	done
	echo "fclose(fp);" >> $matscript

	# HV table
	echo "A=[];" >> $matscript
	for alg in $ALG; do
		echo "A=[A, $alg];" >> $matscript
	done
	if [ $RUN -le 1 ]; then
		echo "A=[A;A];" >> $matscript
	fi
	echo "M=mean(A);" >> $matscript
	echo "S=std(A);" >> $matscript
	echo "[V,I]=max(M);" >> $matscript
	echo "for i=1:size(M,2)" >> $matscript
	echo "if i == I" >> $matscript
		echo "fprintf(',\\\\colorbox{lightgray}{%.4e(%.2e)',  M(1,i), S(1,i));" >> $matscript
		# ranksum
		echo "if i < size(M,2)" >> $matscript
			echo "[p,h]=ranksum(A(:,i), A(:,end),'tail','both');" >> $matscript
			echo "if h == 0" >> $matscript
				echo "fprintf('\$\\\\approx\$');" >> $matscript
			echo "else" >> $matscript
				echo "[p,h]=ranksum(A(:,i), A(:,end),'tail','right');" >> $matscript
					echo "if h == 0" >> $matscript
						echo "fprintf('\$-\$');" >> $matscript
					echo "else" >> $matscript
						echo "fprintf('\$+\$');" >> $matscript
					echo "end" >> $matscript
			echo "end" >> $matscript
		echo "end" >> $matscript
		echo "fprintf('}');" >> $matscript
	echo "else" >> $matscript
		echo "fprintf(',%.4e(%.2e)',  M(1,i), S(1,i));" >> $matscript
		# ranksum
		echo "if i < size(M,2)" >> $matscript
			echo "[p,h]=ranksum(A(:,i), A(:,end),'tail','both');" >> $matscript
			echo "if h == 0" >> $matscript
				echo "fprintf('\$\\\\approx\$');" >> $matscript
			echo "else" >> $matscript
				echo "[p,h]=ranksum(A(:,i), A(:,end),'tail','right');" >> $matscript
					echo "if h == 0" >> $matscript
						echo "fprintf('\$-\$');" >> $matscript
					echo "else" >> $matscript
						echo "fprintf('\$+\$');" >> $matscript
					echo "end" >> $matscript
			echo "end" >> $matscript
		echo "end" >> $matscript
	echo "end" >> $matscript
	echo "end" >> $matscript
	
	# run matlab script
	v=$(echo $(cat $matscript | matlab -nojvm -nodisplay) | sed 's/,/ \& /g')
	rm $matscript
	v=${v%>>*}
	v=${v##*>>}

	line="$line $v \\\\"
	echo $line  >> $outfile.tex
	echo "\\specialrule{0em}{-2pt}{-2pt}" >> $outfile.tex
done
done
done
echo "\\specialrule{0em}{0pt}{0pt}" >> $outfile.tex
echo "\\bottomrule" >> $outfile.tex
echo "\\end{tabular}}}" >> $outfile.tex
echo "\\end{table*}" >> $outfile.tex
echo "\\end{document}" >> $outfile.tex
