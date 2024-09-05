#!/bin/bash

# if false; then
# create indicator value
./shell/hv.sh
./shell/igd.sh
# ./bin/gd

########################################################################################################################
# creat a tree using data
########################################################################################################################
subpro=/tmp/t$$$$.sh
echo "#!/bin/bash" > $subpro
echo "" >> $subpro

echo "pro=\$(echo \${1##*/} | sed 's/^\([A-Z]*[0-9]*\)o\([0-9]*\)v\([0-9]*\)_\(.*\)_\(.*\)_\(.*\)\$/\1/g')" >> $subpro
echo "obj=\$(echo \${1##*/} | sed 's/^\([A-Z]*[0-9]*\)o\([0-9]*\)v\([0-9]*\)_\(.*\)_\(.*\)_\(.*\)\$/\2/g')" >> $subpro
echo "var=\$(echo \${1##*/} | sed 's/^\([A-Z]*[0-9]*\)o\([0-9]*\)v\([0-9]*\)_\(.*\)_\(.*\)_\(.*\)\$/\3/g')" >> $subpro
echo "alg=\$(echo \${1##*/} | sed 's/^\([A-Z]*[0-9]*\)o\([0-9]*\)v\([0-9]*\)_\(.*\)_\(.*\)_\(.*\)\$/\4/g')" >> $subpro
echo "ind=\$(echo \${1##*/} | sed 's/^\([A-Z]*[0-9]*\)o\([0-9]*\)v\([0-9]*\)_\(.*\)_\(.*\)_\(.*\)\$/\5/g')" >> $subpro
echo "key=\$(echo \${1##*/} | sed 's/^\([A-Z]*[0-9]*\)o\([0-9]*\)v\([0-9]*\)_\(.*\)_\(.*\)_\(.*\)\$/\6/g')" >> $subpro
echo "val=\$(cat \$1)" >> $subpro
echo "tmp=output/\${pro}o\${obj}v\${var}_\${alg}_fitness_\${key}" >> $subpro
echo "fit=\$(cat \$tmp)" >> $subpro
echo "" >> $subpro

echo "dir=/tmp/data" >> $subpro
echo "arr=(\$pro \$obj \$var \$alg \$ind \$val \$fit)" >> $subpro
echo "for i in 4 0 1 2 3; do" >> $subpro
echo "	 dir=\${dir}/\${arr[\${i}]}" >> $subpro
echo "	 mkdir -p \$dir" >> $subpro
echo "done" >> $subpro
echo "echo \${arr[5]} >> \$dir/\$(printf '%010d' \${arr[6]%%.*})" >> $subpro
chmod u+x $subpro

dir=/tmp/data
mkdir -p $dir
rm -fr $dir/*
find output -name "*_hv_*"  | sed '/^$/d' | xargs -n 1 -P 8  $subpro
find output -name "*_igd_*" | sed '/^$/d' | xargs -n 1 -P 8  $subpro
# find output -name "*_gd_*"  | sed '/^$/d' | xargs -n 1 -P 8  $subpro
find output -name "*_runtime_*"  | sed '/^$/d' | xargs -n 1 -P 8  $subpro
rm $subpro

# fi
########################################################################################################################
# plot
########################################################################################################################
# if false; then
output=/tmp/evolute.m
cat /dev/null > $output
for ind in $(ls /tmp/data); do
	for pro in $(ls /tmp/data/$ind); do
		for obj in $(ls /tmp/data/$ind/$pro); do
			for var in $(ls /tmp/data/$ind/$pro/$obj); do
				echo "figure" >> $output
				legend=""
				arr=('o' '+' '*' '.' 'x' 's' 'd' '<' '>' '^' 'v' 'p' 'h')
				i=0;
				for alg in $(ls /tmp/data/$ind/$pro/$obj/$var); do
					if [ "$legend" = "" ]; then
						legend="'${alg}'"
					else
						legend="$legend, '$alg'"
					fi
					echo "$alg=[" >> $output
					for fitness in $(ls /tmp/data/$ind/$pro/$obj/$var/$alg); do
						file=/tmp/data/$ind/$pro/$obj/$var/$alg/$fitness
						echo $fitness, $(./shell/mean $(cat $file)) >> $output
					done
					echo "];" >> $output
					echo "[A, I]=sort($alg);" >> $output
			echo "plot($alg(I(:,1),1)./1.0e+4, $alg(I(:,1),2), 'LineWidth', 4, '-${arr[$i]}');" >> $output
			echo "text($alg(I(end,1),1)./1.0e+4, $alg(I(end,1),2), '\\leftarrow $alg');" >> $output
					echo "hold on" >> $output
					echo "title('$ind in $pro with [obj,var]=[$obj, $var]');" >> $output
					echo "xlabel('fitness(x 1.0e+4)');" >> $output
					echo "ylabel('$ind');" >> $output
					i=$[ $i + 1 ]
				done
				if [ "$ind" = "hv" ]; then 
					echo "legend($legend, 'Location', 'southeast');" >> $output
				elif [ "$ind" = "runtime" ]; then 
					echo "legend($legend, 'Location', 'northwest');" >> $output
				else 
					echo "legend($legend, 'Location', 'northeast');" >> $output
				fi
				echo "print('/tmp/$ind-$pro-$obj-$var','-depsc');" >> $output
			done	
		done
	done
done

rm -f /tmp/*.eps
octave-cli $output

ofs="/tmp/curve.tex"
echo "\\documentclass{article}" > $ofs
echo "\\usepackage{graphicx}" >> $ofs
echo "\\usepackage[a4paper, left=1cm, right=1cm]{geometry}" >> $ofs
echo "\\begin{document}" >> $ofs
for file in /tmp/*.eps; do
echo "\\includegraphics[scale=0.8]{$file}" >> $ofs
echo "\\newpage" >> $ofs
done
echo "\\end{document}" >> $ofs
cd /tmp/
xelatex curve

find /tmp/ -name "*.eps" | xargs -n 1 -P 8 rm
# fi
