#!/bin/bash

# ./tmp/OUTPUT/WFG1/OBJ02/VAR00016/NSEA/igd/RUN01/
h0="./tmp/OUTPUT"		# h0 indicates the root of direction the data is lying at
for h1 in ${h0}/*; do 		# h1 has arrived at the title of problem.
for h2 in ${h1}/*; do		# h2 has arrived at the number of objective. 
for h3 in ${h2}/*; do		# h3 has arrived at the number of variables

h4="${h3}/NSEA"		# h4 has arrived at the title of algorithm
h5="${h4}/ash"		# h5 has arrived the the type of flie

# outfile
tmp=${h5:13}
outfile="./tmp/${tmp//\//_}"
echo "outfile=$outfile"
cat /dev/null > $outfile.m
run=0;
for h6 in ${h5}/*; do	# h6 has arrived the the number of runing 
	run=$[ $run + 1 ]
	echo "R${run} = [" >> $outfile.m
	cat $(ls ${h6}/* | tail -n 1) >> $outfile.m
	echo "];" >> $outfile.m
done

# the entire flowchart
echo "h1=figure;" >> $outfile.m
echo "hold on;" >> $outfile.m
for i in $(seq 1 $run); do
	echo "subplot($[ $run / 2 + $run % 2 ], 2, ${i});" >> $outfile.m
	echo "M=R${i}';" >> $outfile.m
	echo "X=M(2:end) - M(1:end-1);" >> $outfile.m
	echo "bar(X);" >> $outfile.m
	echo "box on;" >> $outfile.m
	echo "title('RUN: ${i}');" >> $outfile.m
	echo "set(gca,'xTick', [1, size(X, 2)]); " >> $outfile.m
	echo "set(gca,'xticklabel', [1, size(X, 2)]);" >> $outfile.m
	echo "xlim([1, size(X, 2)]);" >> $outfile.m
	echo "xlabel('Number of Ash');" >> $outfile.m
	echo "ylabel('Value of Ash');" >> $outfile.m
done

echo "print('$outfile.png', '-dpng');" >> $outfile.m

# perform the matlab script	
octave-cli $outfile.m

done
done
done
