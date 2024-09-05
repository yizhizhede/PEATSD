#!/bin/bash

# ./tmp/OUTPUT/WFG1/OBJ02/VAR00016/NSEA/igd/RUN01/
h0="./tmp/OUTPUT"		# h0 indicates the root of direction the data is lying at
for h1 in ${h0}/*; do 		# h1 has arrived at the title of problem.
for h2 in ${h1}/*; do		# h2 has arrived at the number of objective. 
for h3 in ${h2}/*; do		# h3 has arrived at the number of variables

h4="${h3}/NSEA"			# h4 has arrived at the title of algorithm
h5="${h4}/desire"		# h5 has arrived the the type of flie

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
	echo "M=R${i};" >> $outfile.m
	echo "X=1:size (M, 1);" >> $outfile.m
	echo "Y=1:size (M, 2);" >> $outfile.m
	echo "[x, y]=meshgrid (X, Y);" >> $outfile.m
	echo "z=x;" >> $outfile.m
	echo "for i=1:size(z, 1)" >> $outfile.m
	echo "for j=1:size(z, 2)" >> $outfile.m
	echo "z(i, j)=M(x(i, j), y(i, j));" >> $outfile.m
	echo "end" >> $outfile.m
	echo "end" >> $outfile.m
	echo "mesh (x, y, z);" >> $outfile.m
	echo "title('RUN: ${i}');" >> $outfile.m
	echo "xlim([1, size(M, 1)]);" >> $outfile.m
	echo "ylim([1, size(M, 2)]);" >> $outfile.m
	echo "xlabel('Value of Variables');" >> $outfile.m
	echo "ylabel('Number of Variables');" >> $outfile.m
done
done
done
done
