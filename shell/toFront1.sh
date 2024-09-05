#!/bin/bash

for file in output/*_obj_*; do
	echo $file
	./bin/tool F1 $file > /tmp/front1
	cat /tmp/front1 > $file 
done
