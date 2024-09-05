#!/bin/bash

# ./tmp/OUTPUT/WFG1/OBJ02/VAR00016/NSEA/igd/RUN01/
h0="./tmp/OUTPUT"		# h0 indicates the root of direction the data is lying at
for h1 in ${h0}/*; do 		# h1 has arrived at the title of problem.
for h2 in ${h1}/*; do		# h2 has arrived at the number of objective. 
for h3 in ${h2}/*; do		# h3 has arrived at the number of variables

# outfile
tmp=${h3:13}
outfile="./tmp/${tmp//\//_}_front_4D"
echo "outfile=$outfile"
cat /dev/null > $outfile.m
nalg=0
algs=""
for h4 in ${h3}/*; do		# h4 has arrived at the title of algorithm
	nalg=$[ $nalg + 1 ]	# The number of algorithm
	algs="$algs ${h4##*/}"
	h5="${h4}/obj"		# h5 has arrived the the type of flie
	h6="$h5/RUN01"		# h6 has arrived the the number of runing 
	fn=$(ls ${h6}/* | tail -n 1)
	
	echo "R${nalg} = [" >> $outfile.m
	cat $fn >> $outfile.m
	echo "];" >> $outfile.m
done

str=(${algs})
# the entire flowchart
echo "h1=figure;" >> $outfile.m
echo "hold on;" >> $outfile.m
gg=""
for i in $(seq 1 $nalg); do
	echo "subplot($[ $nalg / 2 + $nalg % 2 ], 2, ${i});" >> $outfile.m
	echo "M=R${i};" >> $outfile.m
	echo "X=1:1:size(M, 2);" >> $outfile.m
	echo "plot(X, M, 'Color', 'b');" >> $outfile.m
	echo "title('${str[ $[ ${i} - 1 ] ]}');" >> $outfile.m
	echo "set(gca,'XTick', X);" >> $outfile.m
	echo "xlabel('Number of objective');" >> $outfile.m
	echo "ylabel('Value of objective');" >> $outfile.m
done

echo "print('$outfile.png', '-dpng');" >> $outfile.m

# perform the matlab script	
octave-cli $outfile.m

done
done
done
