#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <mpi.h>
#include <gperftools/profiler.h>
#include <gperftools/heap-profiler.h>

#include "moea.h"

int main (int argc, char **argv)
{
	// srand
	srand (time (NULL));
#ifdef  part_release 
	printf ("The release version, MOEA (moea),  with -O3.\n");
#endif

#ifdef part_debug 
	Population_t*	pop = NULL;
	Parameter_t*	parameter = NULL;
	Problem_t*	problem = NULL;
	int 		comm_rank, comm_size;

	/* MPI init */
	MPI_Init (&argc, &argv);

	/* MPI rank and size*/
	MPI_Comm_rank (MPI_COMM_WORLD, &comm_rank);
	MPI_Comm_size (MPI_COMM_WORLD, &comm_size);

	/* 1. load parameter */
	Parameter_load (argc, argv);	
	
	/* 2. print parameter to std out */
	if (0 == comm_rank) Parameter_print ();

	/* 3. get a parameter */
	parameter = Parameter_get ();

	/* 4. initilize problem */
	problem = Problem_new ();
#endif

#ifdef part_profiler_cpu
	ProfilerStart ("./profile/main.prof");
#endif

#ifdef part_profiler_heap
	HeapProfilerStart ("./profile/main.hprof");
#endif

#ifdef part_debug
	/* 5. algorithm */
	pop = moea (parameter->algorithm, problem);

	/* 6. free pop */
	if (pop != NULL)
		Population_free (&pop);

	/* MPI Finalize */
	MPI_Finalize ();
#endif

#ifdef part_profiler_cpu
	ProfilerStop ();
#endif

#ifdef part_profiler_heap
	HeapProfilerStop ();
#endif


#ifdef  part_hv 
	Matrix_t *M = Matrix_read (argv[1]);
	Matrix_t *bound = Matrix_read (argv[2]);	
	Matrix_t *normM = Matrix_norm (M, bound);
	Matrix_t *F1 = Matrix_front (normM);
	Matrix_t *C  = Matrix_compress (F1);
	printf ("%.16f\n", hv (C));
	return 0;
#endif

#ifdef	part_igd 
	char fn[128], buf[64];
	int  i;

	strcpy (buf, argv[1]);	
	for (i=0; buf[i] != 'v' && buf[i] != '\0'; i++){};
	buf[i] = '\0';
	sprintf (fn, "/tmp/%s-sample", buf);

	Matrix_t *S = Matrix_read (argv[1]);
	Matrix_t *sample = Matrix_read (fn);
	printf("%.16f\n", distance_m2m (sample, S));
	return 0;
#endif

#ifdef	part_sample 
	char fn[64];
 	Matrix_t  *sample = Problem_sample (argv[1], atoi (argv[2]));
	sprintf (fn, "/tmp/%so%02d-sample", argv[1], atoi(argv[2]));
	Matrix_print (sample, fn);
	return 0;
#endif

#ifdef	part_gd 
	GD ();
#endif

#ifdef	part_tool 
	if (!strcmp (argv[1], "max")) {
		Matrix_t *M = Matrix_read (argv[2]);
		M = Matrix_max (M);
		Matrix_print (M);
	} else if (!strcmp (argv[1], "min")) {
		Matrix_t *M = Matrix_read (argv[2]);
		M = Matrix_min (M);
		Matrix_print (M);
	} else if (!strcmp (argv[1], "norm")) {
		Matrix_t *M = Matrix_read (argv[2]);
		Matrix_t *bound = Matrix_read (argv[3]);
		Matrix_t *m = Matrix_read (argv[4]);
		Matrix_cat (&bound, m);
		M = Matrix_norm (M, bound);
		Matrix_print (M);
	} else if (!strcmp (argv[1], "F1")) {
		Matrix_t *M = Matrix_read (argv[2]);
		M = Matrix_front (M);
		M = Matrix_compress (M);
		Matrix_print (M);
	} else if (!strcmp (argv[1], "epsilon")) {
		Matrix_t *A = Matrix_read (argv[2]);
		Matrix_t *R = Matrix_read (argv[3]);
		printf ("%f\n",Iepsilon_plus (A, R));
	} else {
		printf ("command is woring\n");
	}
#endif
	return 0;
}
