#!/bin/bash

# get the number of CPU(s)
line=$(lscpu | sed -n '5p')
arr=($line)
CPUs=${arr[1]}
dir=/tmp/problem

# 
mkdir -p $dir
rm -f $dir/*

cd output
sub=/tmp/sub$$$$.sh
echo "#!/bin/bash" > $sub
echo "tmp=\$(echo \$1 | sed 's/^\(.*\)v\(.*\)\$/\1/g')" >> $sub
echo "touch $dir/\$tmp" >> $sub
chmod u+x $sub
find . -name "*_obj_*" | xargs -n 1 -P $CPUs $sub
rm $sub


tasks=/tmp/list-igd-$$$$
ls $dir | sed 's/o/ /g' > $tasks 
rm -fr $dir
cd ..
cat $tasks | xargs -n 2 -P $CPUs  ./bin/sample
rm $tasks

cd output
sub=/tmp/sub$$$$.sh
echo "#!/bin/bash" > $sub
echo "file=\$1" >> $sub
echo "igd=\$(../bin/igd \${file##*/})" >> $sub
echo "echo \$igd > \$(echo \$1 | sed 's/obj/igd/g')" >> $sub
chmod u+x $sub
find . -name "*_obj_*" | xargs -n 1 -P $CPUs $sub
rm $sub
