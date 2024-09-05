#/bin/bash

# input: PRO, OBJ, VAR, ALG, RUN
source ./Args_for_shell.sh

# the title of table
outfile="./tmp/tex-of-time.tex"

# head of document
echo "\\documentclass{IEEEtran}" > $outfile
echo "\\input{/Users/fengyin/Documents/TeX/package.tex}" >> $outfile
echo "\\begin{document}" >> $outfile

for obj in $OBJ; do
for var in $VAR; do
for pro in $PRO; do
	echo "\\begin{figure}" >> $outfile
	echo "\\centering" >> $outfile
	echo "\\includegraphics[width=0.45\\textwidth]{Time-$pro-$(printf '%02d' $obj)-$(printf '%05d' $var)}" >> $outfile
	echo "\\caption{$pro with $obj objectives $var decision variables.}" >> $outfile
	echo "\\label{fig:chart-of-time-curve-$pro-$obj-$var}" >> $outfile
	echo "\\end{figure}" >> $outfile
done
done
done

echo "\\end{document}" >> $outfile
