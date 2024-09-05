#!/bin/bash

# Algorithms
EAS="NSEA"
# EAS="NSGAII"
# EAS="MOEAD"
# EAS="NSGAIII"
# EAS="TWOARCH2"

#
PER_VAR=100000		# the number of fitness
PER_CAS=20		# The number of runs

# 
outfile="./tmp/list_of_parameters"
num_of_line=0
num_of_task=24

# 
rm -f $outfile*

####################################  generate lists of parameters. ######################################################
for VAR in 8 16 32 64 128 256 512 1024; do	# The number of variable
for PRO in DTLZ1 DTLZ2 DTLZ3 DTLZ4 DTLZ5 DTLZ6 DTLZ7 WFG1 WFG2 WFG3 WFG4 WFG5 WFG6 WFG7 WFG8 WFG9; do	# Problems
for ALG in ${EAS}; do				# Algorithms
for RUN in $(seq 1 ${PER_CAS}); do 		# The number of runing
	echo $ALG $PRO 2 $VAR 100 $[ $VAR*${PER_VAR} ] $RUN >> ${outfile}$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]

	echo $ALG $PRO 3 $VAR 105 $[ $VAR*${PER_VAR} ] $RUN >> ${outfile}$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
done
done

####################################  generate shell scripts of tasks. ######################################################
for task in ${outfile}*; do
	echo "#!/bin/bash" > ${task}.sh
	cat $task | while read line; do
		echo "./bin/moea $line & " >> ${task}.sh
		echo "sleep 1" >> ${task}.sh
	done
	echo "wait" >> ${task}.sh
	chmod u+x ${task}.sh
done

####################################  submit ################################################
for task in ${outfile}*.sh; do
	p=$(yhqueue | wc -l )
	while [ $p -ge 85 ]; do
		sleep 10
		p=$(yhqueue | wc -l )
	done
	
	yhbatch -p work -N 1 $task
	touch ${task##*/}	# record
	sleep 1
done
