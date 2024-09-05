#/bin/bash

# input: PRO, OBJ, VAR, ALG, RUN
source ./Args_for_shell.sh

# the title of table
outfile="./tmp/tex-of-var.tex"

# head of document
echo "\\documentclass{IEEEtran}" > $outfile
echo "\\input{/Users/fengyin/Documents/TeX/package.tex}" >> $outfile
echo "\\begin{document}" >> $outfile

for pro in $PRO; do
for obj in $OBJ; do
for var in $VAR; do
         echo "\\begin{figure*}" >> $outfile
         echo "\\centering" >> $outfile
for alg in $ALG; do
         echo "\\includegraphics[scale=0.22]{Var-$pro-$(printf '%02d' $obj)-$(printf '%05d' $var)-$alg}" >> $outfile
done
         echo "\\caption{$pro with $obj objectives $var variables.}" >> $outfile
         echo "\\label{fig:chart-of-var-$pro-$obj-$var}" >> $outfile
         echo "\\end{figure*}" >> $outfile
done
done
done

echo "\\end{document}" >> $outfile
