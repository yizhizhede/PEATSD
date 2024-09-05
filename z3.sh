#!/bin/bash

# hostname
echo $(hostname) > on_the_host

# clear the historical datum
./clean_log_output.sh

# clear the compiling files 
make clean 

# compile 
make

# check if it is a safe place
if [ $(./shell/is_On_Safe_Place.sh) -lt 1 ]; then
	if false; then
		find . -name "*.cpp" | xargs -n 1 -P 1 rm			
		find . -name "*.h"   | xargs -n 1 -P 1 rm			
	fi	
fi

# submit tasts 
if [ "$(whoami)" = "hebut_bincao_2" ]; then
	# add octave
	module add octave

	#
	./shell/submit_on_server.sh	
else
	./shell/submit_on_local.sh
fi
echo "The progroms have been finished. Now it starts to plot..."

if true; then
	# compute the hv 
	./shell/hv.sh

	# make the tree of datum
	./shell/tree_of_output.sh

	# make table of tree.
	./shell/table_of_igd.sh > /dev/null
	./shell/table_of_hv.sh > /dev/null
	./shell/table_of_time.sh > /dev/null
fi

if true; then
	# make line chart.
	./shell/line_char_of_igd.sh > /dev/null
	./shell/line_char_of_hv.sh > /dev/null
	./shell/line_char_of_time.sh > /dev/null

	# make figures.
	./shell/fig_of_front_2D.sh > /dev/null
	./shell/fig_of_front_3D.sh > /dev/null
	./shell/fig_of_front_4D.sh > /dev/null
	./shell/fig_of_var.sh > /dev/null
	./shell/fig_of_ash.sh > /dev/null

	# mesh of desire
	./shell/mesh_of_desire.sh > /dev/null 
fi

# package of the output
if false && [ "$(whoami)" = "hebut_bincao_2" ]; then
 	yhbatch -N 1 ./shell/package_of_output.sh
fi
