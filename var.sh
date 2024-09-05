#!/bin/bash

rm -f var-run*.png
i=1
for file in output/*_var_*; do
	echo $file
	echo "A=dlmread('${file}');" > var.m
	echo "P=[];" >> var.m
	echo "for i=1:size(A, 2);" >> var.m
	echo "P=[P;repmat([i], [size(A, 1), 1])];" >> var.m 
	echo "end" >> var.m
	echo "P=[P, reshape(A, [size(P), 1])];" >> var.m
#	echo "scatter (P(size(A, 1)+1:end,1), P(size(A,1)+1:end,2));" >> var.m
	echo "scatter (P(:,1), P(:,2));" >> var.m
	echo "box on;" >> var.m
	echo "grid on;" >> var.m
    	echo "axis([1, size(A,2), min(min(A)), max(max(A))]);" >> var.m
#	echo "set(gca,'XTick',[2:2:size(A, 2)]);" >> var.m
    	echo "print('var-run$(printf '%03d' $i)', '-dpng');" >> var.m

	octave-cli ./var.m
	rm -f var.m

#	exit

	i=$[ $i + 1 ]
done
