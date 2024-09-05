#!/bin/bash

# 1. generate the script 
outfile="./tmp/generate_tree.sh"

## 1.0) check if the input is correct
echo "#!/bin/bash" > $outfile
echo "if [ \${#1} -le 10 ]; then" >> $outfile
echo "exit" >> $outfile
echo "fi" >> $outfile

## 1.1) analysis intput and get L0-6
echo "line=\${1##*/}" >> $outfile
echo "oldIFS=\$IFS" >> $outfile
echo "IFS=\"_\"" >> $outfile
echo "arr=(\$line)" >> $outfile
echo "IFS=\$oldIFS" >> $outfile
echo "L0=./tmp/OUTPUT" >> $outfile		# 0. The root of file
echo "L1=\${L0}/\${arr[0]%%o*}" >> $outfile	# 1. The title of problem.
echo "T=\${arr[0]%%v*}" >> $outfile		#
echo "L2=\${L1}/OBJ\${T##*o}" >> $outfile	# 2. The number of objectives
echo "L3=\${L2}/VAR\${arr[0]##*v}" >> $outfile 	# 3. The number of variables
echo "L4=\${L3}/\${arr[1]}" >> $outfile		# 4. The title of algorithm
echo "L5=\${L4}/\${arr[2]}" >> $outfile		# 5. The typle of file
echo "L6=\${L5}/RUN\${arr[3]}" >> $outfile	# 6. The number of runing

## 1.2) make tree of L0-6 
for i in $(seq 0 6); do
	echo "if [ ! -d  \$L$i ]; then" >> $outfile
	echo "mkdir -p \$L$i" >> $outfile
	echo "fi" >> $outfile
done

## 1.3) copy file 
echo "cp \${1} \$L6/" >> $outfile

# 2. authorize
chmod u+x $outfile

# 3. clean history 
rm -rf ./tmp/OUTPUT

# get the number of CPU(s)
line=$(lscpu | sed -n '5p')
arr=($line)
CPUs=${arr[1]}

# 4. perfrom the script
find output   | xargs -n 1 -P ${CPUs} $outfile
