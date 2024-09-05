#!/bin/bash

outfile="/tmp/score$$$$"
echo 0 > $outfile

# check Mac Address
ifconfig -a | sed -n '/^.*:.*:.*:.*:.*:.*$/p' | while read line; do
	arr=($line)
	if [ "ac:de:48:00:11:22" = "${arr[1]}" ]; then		# MacBook Pro
		score=$(cat $outfile)
		score=$[ $score + 1 ]
		echo $score > $outfile
	elif [ "a6:83:e7:1d:c2:f7" = "${arr[1]}" ]; then
		score=$(cat $outfile)
		score=$[ $score + 1 ]
		echo $score > $outfile
	elif [ "a4:83:e7:1d:c2:f7" = "${arr[1]}" ]; then
		score=$(cat $outfile)
		score=$[ $score + 1 ]
		echo $score > $outfile
	elif [ "06:83:e7:1d:c2:f7" = "${arr[1]}" ]; then
		score=$(cat $outfile)
		score=$[ $score + 1 ]
		echo $score > $outfile
	elif [ "fa:3b:12:ea:ad:42" = "${arr[1]}" ]; then
		score=$(cat $outfile)
		score=$[ $score + 1 ]
		echo $score > $outfile
	elif [ "12:00:30:80:2e:01" = "${arr[1]}" ]; then
		score=$(cat $outfile)
		score=$[ $score + 1 ]
		echo $score > $outfile
	elif [ "12:00:30:80:2e:00" = "${arr[1]}" ]; then
		score=$(cat $outfile)
		score=$[ $score + 1 ]
		echo $score > $outfile
	elif [ "12:00:30:80:2e:05" = "${arr[1]}" ]; then
		score=$(cat $outfile)
		score=$[ $score + 1 ]
		echo $score > $outfile
	elif [ "12:00:30:80:2e:04" = "${arr[1]}" ]; then
		score=$(cat $outfile)
		score=$[ $score + 1 ]
		echo $score > $outfile
	elif [ "12:00:30:80:2e:01" = "${arr[1]}" ]; then
		score=$(cat $outfile)
		score=$[ $score + 1 ]
		echo $score > $outfile
	elif [ "${arr[1]}" = "d4:be:d9:73:c2:fa" ]; then		# Alien
		score=$(cat $outfile)
		score=$[ $score + 1 ]
		echo $score > $outfile  
	elif [ "${arr[1]}" = "84:a6:c8:e8:13:18" ]; then		 
		score=$(cat $outfile)
		score=$[ $score + 1 ]
		echo $score > $outfile  
	fi
done

# check hostname
if [ "$(hostname)" = "Fengs-MacBook-Pro.local" ]; then
	score=$(cat $outfile)
	score=$[ $score + 1 ]
	echo $score > $outfile  
fi
if [ "$(hostname)" = "yinfeng-M17xR4" ]; then
	score=$(cat $outfile)
	score=$[ $score + 1 ]
	echo $score > $outfile  
fi

score=$(cat $outfile)
rm $outfile
echo $score
