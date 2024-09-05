#!/bin/bash

for file in *.tar; do
	echo $file
	tar -xf $file
	./shell/tree_of_output_mv_2.0.sh
done
