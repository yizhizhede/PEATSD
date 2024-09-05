#!/bin/bash

ifconfig | grep broadcast | while read line; do
	arr=($line)
	echo "scp $(whoami)@${arr[1]}:$(pwd)/tmp/*.eps ."
	echo "scp $(whoami)@${arr[1]}:$(pwd)/tmp/*.tex ."
	echo "scp $(whoami)@${arr[1]}:$(pwd)/tmp/*.m ."
done
