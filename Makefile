#Makefile file

# compiler 
CC := mpic++

# option
FLAGS = -Wall -Iinclude # -no-multibyte-chars

# include director 
VPATH = include : src : bin

#
.PHONY : all clean test cpu heap run submit tree trim slim addigd fig table lostfound package unpackage ip 

# 
all : main moea hv sample igd gd tool cpu_profiler heap_profiler

#

# source file
src := $(filter %.c %.cxx %.cpp %.cu %.mpi,$(shell find .))

# dependent file
dependents := $(addsuffix .d,$(basename $(src)))
-include $(dependents)

# objective file 
objectives := $(addsuffix .o,$(basename $(src)))

#
main : $(objectives)
	$(CC) $(FLAGS) -Dpart_debug -g $^ -o bin/$@ -lm -lprofiler 
moea : 
	$(CC) $(FLAGS) -Dpart_debug -Dpart_release -O3 $(src) -o bin/$@ -lm -lprofiler 
hv : 
	$(CC) $(FLAGS) -Dpart_hv -O3 $(src) -o bin/$@ -lm -lprofiler -ltcmalloc 
sample: 
	$(CC) $(FLAGS) -Dpart_sample -O3 $(src) -o bin/$@ -lm -lprofiler 
igd : 
	$(CC) $(FLAGS) -Dpart_igd -O3 $(src) -o bin/$@ -lm -lprofiler 
gd : 
	$(CC) $(FLAGS) -Dpart_gd -O3 $(src) -o bin/$@ -lm -lprofiler 
tool: 
	$(CC) $(FLAGS) -Dpart_tool -O3 $(src) -o bin/$@ -lm -lprofiler 
cpu_profiler: 
	$(CC) $(FLAGS) -Dpart_profiler_cpu -Dpart_debug -g $(src) -o bin/$@ -lm -lprofiler -ltcmalloc  
heap_profiler: 
	$(CC) $(FLAGS) -Dpart_profiler_heap -Dpart_debug -g $(src) -o bin/$@ -lm -lprofiler -ltcmalloc  
# 
%.o : %.c
	$(CC) -c $(FLAGS) -Dpart_debug $< -o $@
%.o : %.cpp
	$(CC) -c $(FLAGS) -Dpart_debug $< -o $@
%.o : %.cxx
	$(CC) -c $(FLAGS) -Dpart_debug $< -o $@
%.o : %.mpi
	$(CC) -c $(FLAGS) -Dpart_debug $< -o $@

# 
%.d : %.c
	@set -e; rm -f $@; \
	$(CC) -MM $(FLAGS) $< > $@.$$$$; \
	sed 's,\(.*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$
%.d : %.cpp
	@set -e; rm -f $@; \
	$(CC) -MM $(FLAGS) $< > $@.$$$$; \
	sed 's,\(.*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$
%.d : %.cxx
	@set -e; rm -f $@; \
	$(CC) -MM $(FLAGS) $< > $@.$$$$; \
	sed 's,\(.*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$
%.d : %.mpi
	@set -e; rm -f $@; \
	$(CC) -MM $(FLAGS) $< > $@.$$$$; \
	sed 's,\(.*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$
#
clean:
	-rm -f $(objectives) $(dependents) ./bin/*  
#
test:
	./bin/main
cpu:
	./shell/cpu.sh
heap:
	./shell/heap.sh
run:
	./bin/main SPCEA    WFG9 2 4 100 80000 1 &
	./bin/main MOEAD    WFG9 2 4 100 80000 1 &
	./bin/main NSGAII   WFG9 2 4 100 80000 1 &
	./bin/main NSGAIII  WFG9 2 4 100 80000 1 &
	./bin/main TWOARCH2 WFG9 2 4 100 80000 1 &
submit:
	nohup ./shell/submit_on_local.sh &
tree:
	nohup ./shell/tree_of_output_mv_2.0.sh &
trim:
	./shell/trim_of_output_2.0.sh
slim:
	./shell/slim_of_output_2.0.sh
addigd:
	nohup ./shell/add_igd_for_tree.sh &
fig:
	./shell/fig_of_igd_2.0.sh
	./shell/fig_of_obj_2.0.sh
	./shell/fig_of_time_2.0.sh
	./shell/fig_of_ash_2.0.sh
table:
	./shell/table_of_obj_2.0.sh   
	./shell/table_of_igd_2.0.sh   
	./shell/table_of_time_2.0.sh 	
lostfound:
	nohup ./shell/lost_found_cases.sh &
package:
	nohup ./shell/package_of_output.sh &
unpackage:
	nohup ./shell/unpackage_of_output.sh &
ip:
	./shell/ip_address.sh
