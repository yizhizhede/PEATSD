#!/bin/bash

# Algorithms
EAS="NSEA"
EAS="NSEA NSGAII"
EAS="MOEAD NSGAII NSGAIII TWOARCH2 NSEA"

# 
PER_VAR=1000		# the number of fitness
PER_VAR=100		# the number of fitness
PER_VAR=15000		# the number of fitness
PER_VAR=20000		# the number of fitness
PER_VAR=10000		# the number of fitness


#
PER_CAS=3		# The number of runs

# 
outfile="./tmp/list_of_parameters"
num_of_line=0
num_of_task=1

# 
rm -f ${outfile}*

####################################  BK1. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
	echo $ALG BK1 2 2 100 $[ 2*${PER_VAR} ]  $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
fi
####################################  DPAM1. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
for VAR in 2 4 8 16; do			# 5. The number of variable
	echo $ALG DPAM1 2 $VAR 100 $[ $VAR*${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
done
fi
####################################  DGO. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
for PRO in DGO1 DGO2; do		# 3. The set of problems
	echo $ALG $PRO 2 1 100 ${PER_VAR} $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
done
fi
####################################  FA1. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
	echo $ALG FA1 3 3 100 $[ 3 * ${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
fi
####################################  FAR1. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
	echo $ALG FAR1 2 2 100 $[ 2 * ${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
fi
####################################  FES. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
for VAR in 2 4 8 16; do			# 5. The number of variable
	echo $ALG FES1 2 $VAR 100 $[ ${VAR}*${PER_VAR} ]  $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
	echo $ALG FES2 3 $VAR 100 $[ ${VAR}*${PER_VAR} ]  $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
	echo $ALG FES3 4 $VAR 100 $[ ${VAR}*${PER_VAR} ]  $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
done
fi
####################################  FF1. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
	echo $ALG FF1 2 2 100 $[ 2*${PER_VAR} ]  $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
fi
####################################  IKK1. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
	echo $ALG IKK1 3 2 100 $[ 2*${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
fi
####################################  IM1. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
	echo $ALG IM1 2 2 100 $[ 2*${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
fi
####################################  JOS1. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
for VAR in 2 4 8 16; do			# 5. The number of variable
	echo $ALG JOS1 2 $VAR 100 $[ ${VAR}*${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]

	echo $ALG JOS2 2 $VAR 100 $[ ${VAR}*${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
done
fi
####################################  KUR1. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
for VAR in 2 4 8 16; do			# 5. The number of variable
	echo $ALG KUR1 2 $VAR 100 $[ $VAR*${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
done
fi
####################################  LRS1. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
	echo $ALG LRS1 2 2 100 $[ 2*${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
fi
####################################  LTDZ1. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
	echo $ALG LTDZ1 3 3 100 $[ 3 * ${PER_VAR} ]  $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
fi
####################################  LE1. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
	echo $ALG LE1 2 2 100 $[ 2 * ${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
fi
####################################  MHHM. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
	echo $ALG MHHM1 3 1 100 ${PER_VAR}  $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]

	echo $ALG MHHM2 3 2 100 $[ 2*${PER_VAR} ]  $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
fi
####################################  MLF. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
	echo $ALG MLF1 2 1 100 ${PER_VAR}  $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]

	echo $ALG MLF2 2 2 100 $[ 2*${PER_VAR} ]  $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
fi
####################################  QV1. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
for VAR in 2 4 8 16; do			# 5. The number of variable
	echo $ALG QV1 2 $VAR 100 $[ $VAR*${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
done
fi
####################################  SCH1. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
	echo $ALG SCH1 2 1 100 ${PER_VAR}  $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
fi
####################################  SP1. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
	echo $ALG SP1 2 2 100 $[ 2*${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
fi
####################################  SSFYY. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
	echo $ALG SSFYY1 2 2 100  $[ 2*${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]

	echo $ALG SSFYY2 2 1 100  ${PER_VAR}  $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
fi
####################################  SK. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
	echo $ALG SK1 2 1 100  ${PER_VAR}  $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]

	echo $ALG SK2 2 4 100  $[ 4*${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
fi
####################################  TKLY1. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
	echo $ALG TKLY1 2 4 100 $[ 4*${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
fi
####################################  VU. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
	echo $ALG VU1 2 2 100 $[ 2*${PER_VAR} ]  $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]

	echo $ALG VU2 2 2 100 $[ 2*${PER_VAR} ]  $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
fi
####################################  VFM. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
	echo $ALG VFM1 3 2 100 $[ 2*${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
fi
####################################  ZLT. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
for VAR in 2 4 8 16; do			# 5. The number of variable
	echo $ALG ZLT1 2 $VAR 100 $[ $VAR * ${PER_VAR}]  $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
done
fi
####################################  MOP. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 	# 1. The number of runing
for ALG in ${EAS}; do			# 2. The set of algorithm
	echo $ALG MOP1 2 1 100 ${PER_VAR}  $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]

	echo $ALG MOP3 2 2 100 $[ 2*${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]

	echo $ALG MOP4 2 3 100 $[ 3*${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]

	echo $ALG MOP5 3 2 100 $[ 2*${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]

	echo $ALG MOP6 2 2 100 $[ 2*${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]

	echo $ALG MOP7 3 2 100 $[ 2*${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]

for VAR in 2 4 8 16; do			# 5. The number of variable
	echo $ALG MOP2 2 $VAR 100 $[ ${VAR}*${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
done
fi

####################################  ZDT. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 		# 1. The number of runing
for ALG in ${EAS}; do				# 2. The set of algorithm
for PRO in ZDT1 ZDT2 ZDT3 ZDT4 ZDT6; do		# 3. The set of problems
for VAR in 2 4 8 16; do				# 5. The number of variable
	echo $ALG $PRO 2 $VAR 100 $[ $VAR*${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
done
done
fi
####################################  DTLZ. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 				# 1. The number of runing
for ALG in ${EAS}; do						# 2. The set of algorithm
for PRO in DTLZ1 DTLZ2 DTLZ3 DTLZ4 DTLZ5 DTLZ6 DTLZ7; do	# 3. The set of problems
for VAR in 8 16 32 64 128 256 512 1024; do			# 5. The number of variable
	echo $ALG $PRO 2 $VAR 100 $[ $VAR*${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]

	echo $ALG $PRO 3 $VAR 105 $[ $VAR*${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
done
done
fi
####################################  WFG. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 				# 1. The number of runing
for ALG in ${EAS}; do						# 2. The set of algorithm
for PRO in WFG1 WFG2 WFG3 WFG4 WFG5 WFG6 WFG7 WFG8 WFG9; do	# 3. The set of problems
for VAR in 8 16 32 64 128 256 512 1024; do			# 5. The number of variable
	echo $ALG $PRO 2 $VAR 100 $[ $VAR*${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]

	echo $ALG $PRO 3 $VAR 105 $[ $VAR*${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
done
done
fi

####################################  LSMOP. ##############################################################################
if false; then
for RUN in $(seq 1 ${PER_CAS}); do 						# 1. The number of runing
for ALG in ${EAS}; do								# 2. The set of algorithm
for PRO in LSMOP1 LSMOP2 LSMOP3 LSMOP4 LSMOP5 LSMOP6 LSMOP7  LSMOP8 LSMOP9; do	# 3. The set of problems
	echo $ALG $PRO 2 100 100 $[ 100*${PER_VAR} ] $RUN >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
done
done
done
fi

#################################### self-defined input. ##################################################################
# self-designed input: PRO, OBJ, VAR, ALG, RUN
source ./Args_for_shell.sh

# generate tasks
if true; then
for run in $(seq 1 ${RUN}); do			# 1. the number of runing
for alg in ${ALG}; do				# 2. the set of algorithm
for pro in ${PRO}; do	
for obj in ${OBJ}; do			
for var in ${VAR}; do			
#	maxFEs=1000000				# maxFEs
#	maxFEs=5000000				# maxFEs
	maxFEs=$[ ${var} * ${PER_VAR} ]		# maxFEs
if [ $obj -eq 2 ]; then
	echo $alg $pro 2 $var 100 $maxFEs $run >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
elif [ $obj -eq 3 ]; then
	echo $alg $pro 3 $var 105 $maxFEs $run >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
else
	echo $alg $pro $obj $var 100 $maxFEs $run >> $outfile$(printf '%08d' $[ $num_of_line / $num_of_task])
	num_of_line=$[ $num_of_line + 1 ]
fi
done
done
done
done
done
fi

# get the number of CPU(s)
line=$(lscpu | sed -n '5p')
arr=($line)
CPUs=${arr[1]}

# set CPUs
if [ $CPUs -gt 4 ]; then
	CPUs=$[ $CPUs - 2 ];
fi

# perform tasks
for task in $outfile*; do
	n=$( top -b -n 1 | grep "moea" | wc -l )
	while [ $n -ge $CPUs ]; do
		sleep 1 
		n=$( top -b -n 1 | grep "moea" | wc -l )
	done

	#
	mpiexec -n 1 ./bin/moea $(cat $task ) &
	touch ${task##*/}	# record
#	sleep 1
done
