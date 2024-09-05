#!/bin/bash

# ./tmp/OUTPUT/WFG1/OBJ02/VAR00016/NSEA/igd/RUN01/
h0="./tmp/OUTPUT"		# h0 indicates the root of direction the data is lying at
for h1 in ${h0}/*; do 		# h1 has arrived at the title of problem.
    h2="${h1}/OBJ03"		# h2 has arrived at the number of objective. 
    if [ ! -d ${h2} ]; then
	echo "${h2} is not a director"
	exit
    fi
for h3 in ${h2}/*; do		# h3 has arrived at the number of variables

# outfile
tmp=${h3:13}
outfile="./tmp/${tmp//\//_}_front_3D"
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
Marker=('o' 'o' '*' '+' 'x' 's' 'd' 'v' '<' '>' 'p' 'h')
gg=""
for i in $(seq 1 $nalg); do
	echo "subplot($[ $nalg / 2 + $nalg % 2 ], 2, ${i});" >> $outfile.m
	echo "M=R${i};" >> $outfile.m
	echo "scatter3(M(:,1), M(:,2), M(:, 3), 'Marker', '${Marker[i]}');" >> $outfile.m
	echo "view([1, 0.5, 1]);" >> $outfile.m
	echo "title('${str[ $[ ${i} - 1 ] ]}');" >> $outfile.m
	echo "xlabel('f1');" >> $outfile.m
	echo "ylabel('f2');" >> $outfile.m
	echo "zlabel('f3');" >> $outfile.m
done

echo "print('$outfile.png', '-dpng');" >> $outfile.m

# perform the matlab script	
octave-cli $outfile.m

done
done
