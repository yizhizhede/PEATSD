#!/bin/bash

# ./tmp/OUTPUT/WFG1/OBJ02/VAR00016/NSEA/igd/RUN01/
h0="./tmp/OUTPUT"		# h0 indicates the root of direction the data is lying at
for h1 in ${h0}/*; do 		# h1 has arrived at the title of problem.
for h2 in ${h1}/*; do		# h2 has arrived at the number of objective. 
for h3 in ${h2}/*; do		# h3 has arrived at the number of variables

# outfile
tmp=${h3:13}
outfile="./tmp/${tmp//\//_}_time_line_char"
echo "outfile=$outfile"
cat /dev/null > $outfile.m
echo "R=[];" >> $outfile.m
nalg=0
algs=""
for h4 in ${h3}/*; do		# h4 has arrived at the title of algorithm
	nalg=$[ $nalg + 1 ]	# The number of algorithm
	algs="$algs,:${h4##*/}:"
	h5="${h4}/time"		# h5 has arrived the the type of flie
	
	run=0;
	for h6 in  $h5/*; do	# h6 has arrived the the number of runing 
		run=$[ $run + 1 ]
		echo "R${nalg}${run} = [" >> $outfile.m
		cat $h6/* >> $outfile.m
		echo "];" >> $outfile.m
	done

	echo "R${nalg}=[];" >> $outfile.m
	while [ $run -gt 0 ]; do	
		echo "R${nalg}=[R${nalg},R${nalg}$[ $run ]];" >> $outfile.m
		run=$[ $run - 1 ]
	done
	echo "if (1 == size(R${nalg}, 2))" >> $outfile.m
	echo "R${nalg}=[R${nalg}, R${nalg}];" >> $outfile.m
	echo "end" >> $outfile.m
	echo "R=[R, mean(R${nalg}')'];" >> $outfile.m
done

str=${algs:1}
legend=${str//:/\'}
Marker=('o' 'o' '*' '+' 'x' 's' 'd' 'v' '<' '>' 'p' 'h')
# the entire flowchart
echo "X=0:1:100;" >> $outfile.m
echo "Y=R;" >> $outfile.m
echo -n "plot (" >> $outfile.m
for i in $(seq 1 $nalg); do
	echo -n "X, Y(:, ${i}), '-${Marker[${i}]}', " >> $outfile.m
done
echo "'LineWidth', 2.8);" >> $outfile.m
echo "box on" >> $outfile.m
echo "title('${outfile//_/:}');" >> $outfile.m
echo "xlabel('progress(%)');" >> $outfile.m
echo "ylabel('Running time (s)');" >> $outfile.m
echo "legend(${legend}, 'Location','NorthWest');" >> $outfile.m
echo "set(gca, 'Xlim', [0, 100]);" >> $outfile.m
# echo "print('$outfile', '-depsc');" >> $outfile.m
echo "print('$outfile.png', '-dpng');" >> $outfile.m

# perform the matlab script	
octave-cli $outfile.m

done
done
done
