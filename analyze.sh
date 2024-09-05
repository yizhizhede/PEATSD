#!/bin/bash

# tree
./shell/tree_of_output_mv_2.0.sh 

# table
./shell/table_of_igd_2.0.sh  &
# ./shell/table_of_rank_2.0.sh &
./shell/table_of_time_2.0.sh &
./shell/table_of_obj_2.0.sh  &


# tex
./shell/tex_of_igd_1.0.sh & 
./shell/tex_of_obj_1.0.sh &
./shell/tex_of_var_1.0.sh &
./shell/tex_of_time_1.0.sh &


# fig
./shell/fig_of_igd_5.0.sh  &
./shell/fig_of_time_5.0.sh &
./shell/fig_of_obj_3.0.sh  &
./shell/fig_of_var_3.0.sh  &

# wait
wait

# ip
./shell/ip_address.sh
