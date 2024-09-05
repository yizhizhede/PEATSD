#!/bin/bash

# get the number of CPU(s)
line=$(lscpu | sed -n '5p')
arr=($line)
CPUs=${arr[1]}

# clean found cases
cat /dev/null > ./tmp/found-cases

# perform tasks
cat ./tmp/lost-cases | while read line; do
	n=$( ps -A -o command | grep "moea" | wc -l )
	while [ $n -gt $CPUs ]; do
		sleep 10
		n=$( ps -A -o command | grep "moea" | wc -l )
	done

	./bin/moea $line &
	echo "$line" >> ./tmp/found-cases	# record
	sleep 1
done
