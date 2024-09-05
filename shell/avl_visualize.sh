#!/bin/bash

cd latex
for file in avl*.tex ; do
	xelatex $file
	open -a safari ${file%.*}.pdf
done
