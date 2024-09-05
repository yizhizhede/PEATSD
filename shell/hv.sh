#!/bin/bash

# get the number of CPU(s)
line=$(lscpu | sed -n '5p')
arr=($line)
CPUs=${arr[1]}

mkdir -p /tmp/ext
rm -f /tmp/ext/*
rm -f /tmp/*_bound

temp=/tmp/t$$$$.sh
# get min value of each pareto 
echo "#!/bin/bash" > $temp
echo "oldIFS=\$IFS" >> $temp
echo "IFS='_'" >> $temp
echo "arr=(\${1##*/})" >> $temp
echo "IFS=\$oldIFS" >> $temp
echo "./bin/tool min \$1 >> /tmp/ext/\${arr[0]}_min" >> $temp
chmod u+x $temp
find ./output/ -name "*_obj_*" | xargs -n 1 -P ${CPUs} $temp
rm $temp


# get min value
temp=/tmp/t$$$$.sh
echo "#!/bin/bash" > $temp
echo "oldIFS=\$IFS" >> $temp
echo "IFS='_'" >> $temp
echo "arr=(\${1##*/})" >> $temp
echo "IFS=\$oldIFS" >> $temp
echo "./bin/tool min \$1 > /tmp/\${arr[0]}_bound" >> $temp
chmod u+x $temp
find /tmp/ext/ -name "*_min" | xargs -n 1 -P ${CPUs} $temp
rm $temp

# get max value of each pareto 
rm -f /tmp/ext/*
temp=/tmp/t$$$$.sh
echo "#!/bin/bash" > $temp
echo "oldIFS=\$IFS" >> $temp
echo "IFS='_'" >> $temp
echo "arr=(\${1##*/})" >> $temp
echo "IFS=\$oldIFS" >> $temp
echo "./bin/tool max \$1 >> /tmp/ext/\${arr[0]}_max" >> $temp
chmod u+x $temp
find ./output/ -name "*_obj_*" | xargs -n 1 -P ${CPUs} $temp
rm $temp

# get max value
temp=/tmp/t$$$$.sh
echo "#!/bin/bash" > $temp
echo "oldIFS=\$IFS" >> $temp
echo "IFS='_'" >> $temp
echo "arr=(\${1##*/})" >> $temp
echo "IFS=\$oldIFS" >> $temp
echo "./bin/tool max \$1 >> /tmp/\${arr[0]}_bound" >> $temp
chmod u+x $temp
find /tmp/ext/ -name "*_max" | xargs -n 1 -P ${CPUs} $temp
rm $temp
rm -rf /tmp/ext

############################################################################################################
#  compute hv value
############################################################################################################
temp=/tmp/t$$$$.sh
echo "#!/bin/bash" > $temp
echo "oldIFS=\$IFS" >> $temp
echo "IFS='_'" >> $temp
echo "arr=(\${1##*/})" >> $temp
echo "IFS=\$oldIFS" >> $temp
echo "./bin/hv \$1 /tmp/\${arr[0]}_bound > \$(echo \$1 | sed 's/obj/hv/g')" >> $temp
chmod u+x $temp
find output -name "*_obj_*" | xargs -n 1 -P ${CPUs} $temp
rm $temp
rm -f /tmp/*_bound
