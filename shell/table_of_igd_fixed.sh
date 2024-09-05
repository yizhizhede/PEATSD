#!/bin/bash

# Table 1
if true; then
# input: PRO, OBJ, VAR, ALG, RUN
PRO="DTLZ1 DTLZ2 DTLZ3 DTLZ4 DTLZ5 DTLZ6 DTLZ7" 
OBJ="2 3" 						
VAR="256 512 1024" 		
ALG="NSGAII MOEAD NSGAIII TWOARCH2 SMSEMOA SPCEA"
RUN=20

# the title of table
outfile="./tmp/table-of-igd-dtlz"

# head of document
echo "\\documentclass{IEEEtran}" > $outfile.tex
echo "\\input{/Users/fengyin/Documents/TeX/package.tex}" >> $outfile.tex
echo "\\begin{document}" >> $outfile.tex

# begin table
echo "\\begin{table*}" >> $outfile.tex
echo "\\centering" >> $outfile.tex
echo "\\caption{The IGD of algorithms}" >> $outfile.tex
echo "\\label{tab:igd-of-dtlz}" >> $outfile.tex
echo "\\scalebox{0.69}{" >> $outfile.tex

# the head of table
echo "\\begin{tabular}{ccc*{$(echo $ALG | wc -w )}{c}}" >> $outfile.tex
echo "\\toprule" >> $outfile.tex
echo "Pro. & Obj. & VAR. & $(echo $ALG | sed 's/ / \& /g') \\\\" >> $outfile.tex

# the body of table
nCase=-1
for pro in ${PRO}; do
echo "\\midrule" >> $outfile.tex
for obj in ${OBJ}; do 			
if [ $obj -eq 3 ]; then
	echo "\\cline{2-9}" >> $outfile.tex
fi
for var in ${VAR}; do
	nCase=$[ $nCase + 1 ]

	if [ $[ $nCase % 6 ] -eq 0 ]; then
		item1="\\multirow{6}{*}[-0.35cm]{$pro}"
	else
		item1=""
	fi
	if [ $[ $nCase % 3 ] -eq 0 ]; then
		item2="\\multirow{3}{*}[-0.19cm]{$obj}"
	else
		item2=""
	fi
	line="$item1 & $item2 & $var"

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
			h5=$h4/igd
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

	# IGD table
	echo "A=[];" >> $matscript
	for alg in $ALG; do
		echo "A=[A, $alg];" >> $matscript
	done
	if [ $RUN -le 1 ]; then
		echo "A=[A;A];" >> $matscript
	fi
	echo "M=mean(A);" >> $matscript
	echo "S=std(A);" >> $matscript
	echo "[V,I]=min(M);" >> $matscript
	echo "for i=1:size(M,2)" >> $matscript
	echo "if i == I" >> $matscript
	echo "fprintf(',\\\\colorbox{lightgray}{%.4e(%.2e)',  M(1,i), S(1,i));" >> $matscript
		# ranksum
		echo "if i < size(M,2)" >> $matscript
			echo "[p,h]=ranksum(A(:,i), A(:,end),'tail','both');" >> $matscript
			echo "if h == 0" >> $matscript
				echo "fprintf('\$\\\\approx\$');" >> $matscript
			echo "else" >> $matscript
				echo "[p,h]=ranksum(A(:,i), A(:,end),'tail','left');" >> $matscript
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
				echo "[p,h]=ranksum(A(:,i), A(:,end),'tail','left');" >> $matscript
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
done
done
done
echo "\\bottomrule" >> $outfile.tex
echo "\\end{tabular}}" >> $outfile.tex
echo "\\end{table*}" >> $outfile.tex
echo "\\end{document}" >> $outfile.tex
fi

# Table 2
if true; then
# input: PRO, OBJ, VAR, ALG, RUN
PRO="WFG1 WFG2 WFG3 WFG4 WFG5 WFG6 WFG7 WFG8 WFG9"
OBJ="2 3" 						
VAR="256 512 1024" 		
ALG="MOEADVA LMEA WOF DLSMOEA MPMMEA SPCEA"
RUN=20

# the title of table
outfile="./tmp/table-of-igd-wfg"

# head of document
echo "\\documentclass{IEEEtran}" > $outfile.tex
echo "\\input{/Users/fengyin/Documents/TeX/package.tex}" >> $outfile.tex
echo "\\begin{document}" >> $outfile.tex

# begin table
echo "\\begin{table*}" >> $outfile.tex
echo "\\centering" >> $outfile.tex
echo "\\caption{The IGD of algorithms}" >> $outfile.tex
echo "\\label{tab:igd-of-wfg}" >> $outfile.tex
echo "\\scalebox{0.69}{" >> $outfile.tex

# the head of table
echo "\\begin{tabular}{ccc*{$(echo $ALG | wc -w )}{c}}" >> $outfile.tex
echo "\\toprule" >> $outfile.tex
echo "Pro. & Obj. & VAR. & $(echo $ALG | sed 's/ / \& /g') \\\\" >> $outfile.tex

# the body of table
nCase=-1
for pro in ${PRO}; do
echo "\\midrule" >> $outfile.tex
for obj in ${OBJ}; do 			
if [ $obj -eq 3 ]; then
	echo "\\cline{2-9}" >> $outfile.tex
fi
for var in ${VAR}; do
	nCase=$[ $nCase + 1 ]

	if [ $[ $nCase % 6 ] -eq 0 ]; then
		item1="\\multirow{6}{*}[-0.35cm]{$pro}"
	else
		item1=""
	fi
	if [ $[ $nCase % 3 ] -eq 0 ]; then
		item2="\\multirow{3}{*}[-0.19cm]{$obj}"
	else
		item2=""
	fi
	line="$item1 & $item2 & $var"

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
			h5=$h4/igd
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

	# IGD table
	echo "A=[];" >> $matscript
	for alg in $ALG; do
		echo "A=[A, $alg];" >> $matscript
	done
	if [ $RUN -le 1 ]; then
		echo "A=[A;A];" >> $matscript
	fi
	echo "M=mean(A);" >> $matscript
	echo "S=std(A);" >> $matscript
	echo "[V,I]=min(M);" >> $matscript
	echo "for i=1:size(M,2)" >> $matscript
	echo "if i == I" >> $matscript
	echo "fprintf(',\\\\colorbox{lightgray}{%.4e(%.2e)',  M(1,i), S(1,i));" >> $matscript
		# ranksum
		echo "if i < size(M,2)" >> $matscript
			echo "[p,h]=ranksum(A(:,i), A(:,end),'tail','both');" >> $matscript
			echo "if h == 0" >> $matscript
				echo "fprintf('\$\\\\approx\$');" >> $matscript
			echo "else" >> $matscript
				echo "[p,h]=ranksum(A(:,i), A(:,end),'tail','left');" >> $matscript
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
				echo "[p,h]=ranksum(A(:,i), A(:,end),'tail','left');" >> $matscript
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
done
done
done
echo "\\bottomrule" >> $outfile.tex
echo "\\end{tabular}}" >> $outfile.tex
echo "\\end{table*}" >> $outfile.tex
echo "\\end{document}" >> $outfile.tex
fi
