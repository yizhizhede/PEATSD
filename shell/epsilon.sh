#!/bin/bash

cd output

tempdir=/tmp/I
mkdir -p $tempdir 
rm -f $tempdir/*
for file in *_front_*; do
	cp $file $tempdir 
	pro=$(echo $file | sed 's/^\(.*\)_\(.*\)_front_\(.*\)$/\1/g')
	cat $file >> $tempdir/${pro}_front
done

for file in $tempdir/*_front; do
	pre=$(echo $file | sed 's/^\(.*\)_front$/\1/g')
	../bin/tool "max" "$file" > ${pre}_uppBound
	../bin/tool "min" "$file" > ${pre}_lowBound
done

for file in $tempdir/*_front_*; do
	pro=$(echo $file | sed 's/^\(.*\)_\(.*\)_front_\(.*\)$/\1/g')
	out=$(echo $file | sed 's/front/norm/g')
	../bin/tool norm $file ${pro}_lowBound ${pro}_uppBound > $out
done

rm -f /tmp/I/*_front
for file in $tempdir/*_norm_*; do
	pro=$(echo $file | sed 's/^\(.*\)_\(.*\)_norm_\(.*\)$/\1/g')
	cat $file >> ${pro}_front
done

for file in $tempdir/*_front; do
	pre=$(echo $file | sed 's/^\(.*\)_front$/\1/g')
	../bin/tool "F1" "$file" > ${pre}_F1
done


for file in $tempdir/*_norm_*; do
	pro=$(echo $file | sed 's/^\(.*\)_\(.*\)_norm_\(.*\)$/\1/g')
	out=$(echo $file | sed 's/norm/epsilon/g')
	../bin/tool "epsilon" "$file"  ${pro}_F1 > $out
done

for file in $tempdir/*_epsilon_*; do
	cp $file /Users/fengyin/Documents/workspace/moeaFlatform/output
done
