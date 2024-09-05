#!/bin/bash

# file=$(ls output/*obj* | tail -n 1)

rm -f f*.png

# if output is empty
n=$(ls output/ | wc -l )
if [ $n -le 1 ]; then
	echo "output is empty, so exit"
	exit;
fi

# chart of PF
if true; then		# the begin of switch  
i=1;
for file in $(ls output/*obj*); do
	echo "M=dlmread('${file}');" > fig.m
#	echo "F=dlmread('$(ls PF/* )');" >> fig.m
	echo "hold on;" >> fig.m
	echo "if 2 == size(M, 2)" >> fig.m
	echo "box on" >> fig.m
	echo "scatter(M(:,1), M(:,2), 'r', 'filled');" >> fig.m
#	echo "scatter(F(:,1), F(:,2), 2);" >> fig.m
	echo "else" >> fig.m
	echo "X=1:size(M, 2);" >> fig.m
	echo "plot(X, M, 'LineWidth', 1.4, 'Color', 'k');" >> fig.m
	echo "set(gca, 'Xtick', X)" >> fig.m
	echo "box on" >> fig.m
	echo "end" >> fig.m
	echo "hold off;" >> fig.m
	echo "print('f$(printf '%03d' $i)', '-dpng');" >> fig.m
	octave-cli fig.m
	rm -f fig.m

	i=$[ $i + 1 ]
done
fi	# The end 


# chart of HV 
if false; then		# begin of the switch
echo "A=[" > fig.m
i=0;
for file in $(ls output/*hv*); do
	echo "$i, $(cat $file)" >> fig.m	
	i=$[ $i + 1 ]
done
echo "];" >> fig.m
# the entire figure
echo "plot (A(:, 1), exp(A(:, 2)), 'LineWidth', 2.8, 'Marker', 'o', 'MarkerSize', 3, 'Color', 'k')" >> fig.m
echo "box on" >> fig.m
echo "print('f103', '-dpng');" >> fig.m
# the part of figure
for i in 1 21 41 61 81; do
	echo "plot (A(${i}:$[ $i + 20 ], 1), exp(A(${i}:$[ $i + 20 ], 2)), 'LineWidth', 2.8, 'Marker', 'o', 'MarkerSize', 3, 'Color', 'k')" >> fig.m
	echo "box on" >> fig.m
	echo "print('f103-${i}', '-dpng');" >> fig.m
done

octave-cli fig.m
rm -f fig.m
fi			# The end.

# chart of IGD
if true; then		# begin of the switch
echo "A=[" > fig.m
i=0;
for file in $(ls output/*igd*); do
	echo "$i, $(cat $file)" >> fig.m	
	i=$[ $i + 1 ]
done
echo "];" >> fig.m
# the entire flowchart
echo "plot (A(:, 1), log(A(:, 2)), 'LineWidth', 2.8, 'Marker', 'o', 'MarkerSize', 3, 'Color', 'k')" >> fig.m
echo "box on" >> fig.m
echo "print('f104', '-dpng');" >> fig.m
# the parts of flowchart
for i in 1 21 41 61 81; do
	echo "plot (A(${i}:$[ $i + 20 ], 1), log(A(${i}:$[ $i + 20 ], 2)), 'LineWidth', 2.8, 'Marker', 'o', 'MarkerSize', 3, 'Color', 'k')" >> fig.m
	echo "box on" >> fig.m
	echo "print('f104-${i}', '-dpng');" >> fig.m
done

#
octave-cli fig.m
rm -f fig.m
fi			# The end.

# chart of TIME
if true; then		# begin of the switch
echo "A=[" > fig.m
i=0;
for file in $(ls output/*time*); do
	echo "$i, $(cat $file)" >> fig.m	
	i=$[ $i + 1 ]
done
echo "];" >> fig.m
echo "plot (A(:,1), A(:, 2), 'LineWidth', 2.8, 'Color', 'k', 'Marker', 'o', 'MarkerSize', 3)" >> fig.m
echo "box on" >> fig.m
echo "print('f105', '-dpng');" >> fig.m
octave-cli fig.m
rm -f fig.m
fi			# The end
