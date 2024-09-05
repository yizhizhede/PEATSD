#!/bin/bash

if true; then
for file in output/*_front_*; do
	out=/tmp/${file##*/}.m
	cat /dev/null > $out
	echo "M=dlmread('$(pwd)/output/${file##*/}');" >> $out

	echo "if size(M,2) == 2" >> $out
	echo "scatter(M(:,1), M(:,2));" >> $out
	echo "grid on" >> $out
	echo "xlabel('f1');" >> $out
	echo "ylabel('f2');" >> $out
	echo "title('$(echo ${file##*/} | sed 's/^\(.*\)_\(.*\)_front_.*$/\2 on \1/g')');" >> $out
	echo "print('/tmp/${file##*/}', '-depsc');" >> $out
	echo "end" >> $out

	echo "if size(M,2) == 3" >> $out
	echo "scatter3(M(:,1), M(:,2), M(:,3));" >> $out
	echo "grid on" >> $out
	echo "xlabel('f1');" >> $out
	echo "ylabel('f2');" >> $out
	echo "zlabel('f3');" >> $out
	echo "title('$(echo ${file##*/} | sed 's/^\(.*\)_\(.*\)_front_.*$/\2 on \1/g')');" >> $out
	echo "print('/tmp/${file##*/}', '-depsc');" >> $out
	echo "end" >> $out
done
find /tmp/ -name "*.eps" | xargs -n 1 -P  8 rm
find /tmp/ -name "*.m" | xargs -n 1 -P  8 octave-cli
find /tmp/ -name "*.m" | xargs -n 1 -P  8 rm
fi

ofs="/tmp/visualation.tex"
echo "\\documentclass{article}" > $ofs
echo "\\usepackage{geometry}" >> $ofs
echo "\\geometry{a4paper, left=1cm, right=1cm}" >> $ofs
echo "\\usepackage{graphicx}" >> $ofs
echo "\\usepackage{caption, subcaption}" >> $ofs
echo "\\begin{document}" >> $ofs

for file in /tmp/*.eps; do
	echo "\\includegraphics[scale=0.3]{${file}}" >> $ofs
	echo "\\qquad" >> $ofs
done

echo "\\end{document}" >> $ofs

cd /tmp/ 
xelatex ${ofs##*/}
find /tmp/ -name "*.eps" | xargs -n 1 -P 8 rm
