#include "selection.h"
#include "algebra.h"
#include "problem.h"
#include <mpi.h>
#include <string.h>
#include <float.h>

void select_by_RV (double* obj, int popSize, int numObj, double* V, int NR, double* L, double* zmin, int* sel) {
	double	angle, minAngle;
	double 	APD, minAPD, length;
	double 	associate[popSize+10];
	double	gamma[NR+10], beta;
	int	vis[NR+10];
	double	f[popSize*numObj+10];
	int	comm_rank, comm_size;
	int 	i, j, k, a, b;

	// MPI
	MPI_Comm_rank (MPI_COMM_WORLD, &comm_rank);
	MPI_Comm_size (MPI_COMM_WORLD, &comm_size);

	/* 1. Objective Value Translation */
	for (j=0; j<numObj; j++) {
		for (i=0; i<popSize; i++) {
			if (obj[i*numObj+j] < zmin[j]) {
				zmin[j] = obj[i*numObj+j];
			}
		}
		for (i=0; i<popSize; i++) {
			f[i*numObj+j] = obj[i*numObj+j] - zmin[j];
		}
	}

	/* 2. Population Partition; associate */
	for (i=0; i<popSize; i++) {
		b = 0;
		minAngle = vector_angle (f+i*numObj, V+0*numObj, numObj);	
		for (a=1; a<NR; a++) {
			angle = vector_angle (f+i*numObj, V+a*numObj, numObj);	
			if (angle < minAngle) {
				minAngle = angle;
				b = a;
			}
		}
		associate[i] = b;
	}

	/* 3. APD calculation; and 4) the elitism selection */

	// set vis and sel
	memset (vis, 0, NR*sizeof (int));
	memset (sel, 0, popSize*sizeof (int));

	// calculate gamma
	for (a=0; a<NR; a++) { gamma[a] = 1.0e+100; }
	for (a=0; a<NR-1; a++) {
		for (b=a+1; b<NR; b++) {
			angle = vector_angle (V+a*numObj, V+b*numObj, numObj);
			if (angle < gamma[a]) 
				gamma[a] = angle;
			if (angle < gamma[b]) 
				gamma[b] = angle;
		}
	}

	// calculate beta
	beta = (1.0 * comm_size * Problem_getFitness ()) / Problem_getLifetime ();
	beta = (beta > 1.0) ? 1.0 : beta;
	
	// select one for each reference vector
	for (i=0; i<popSize; i++) {		// i: index of individuil
		a = associate[i];		// a: index of reference vector
		if (0 == vis[a]) {
			vis[a] = 1;
			k = -1;
			for (j=0; j<popSize; j++) if (associate[j] == a) { 	// j: index of individual
				angle = vector_angle (f+j*numObj, V+a*numObj, numObj);
				// length = norm (f+j*numObj, numObj);
				for (b=0, length=0; b<numObj; b++) { length += f[j*numObj+b] * L[b]; }
				// calculate APD
				APD = (1 + numObj * beta * beta * angle / gamma[a]) * length;
				if (-1 == k) {
					minAPD = APD;
					k = j;
				} else if (APD < minAPD) {
					minAPD = APD;
					k = j;		
				}
			}
			sel[k] = 1;
		}
	}
}

//
static int ADAPTRV_counter = 1;
//
void adapt_RV (double* obj, int popSize, int numObj, double*V, double* V0, int NR, double* L) {
	int	comm_rank, comm_size;
	double	zmin[numObj+10]; 
	double 	zmax[numObj+10];
	double 	beta, length;
	int 	i, j; 

	// MPI
	MPI_Comm_rank (MPI_COMM_WORLD, &comm_rank);
	MPI_Comm_size (MPI_COMM_WORLD, &comm_size);

	// calculate beta
	beta = (1.0 * comm_size * Problem_getFitness ()) / Problem_getLifetime ();
	beta = (beta > 1.0) ? 1.0 : beta;

	if (beta > 0.1 * ADAPTRV_counter) {
		ADAPTRV_counter++;
		// zmin & zmax
		for (j=0; j<numObj; j++) {
			zmin[j] = obj[0*numObj+j];
			zmax[j] = obj[0*numObj+j];
			for (i=1; i<popSize; i++) {
				if (obj[i*numObj+j] < zmin[j]) {
					zmin[j] = obj[i*numObj+j];
				}
				if (obj[i*numObj+j] > zmax[j]) {
					zmax[j] = obj[i*numObj+j];
				}
			}
			if (zmax[j] - zmin[j] < DBL_EPSILON) return;
		}
		// reference vector
		for (i=0; i<NR; i++) {
			for (j=0; j<numObj; j++) {
				V[i*numObj+j] = V0[i*numObj+j] * (zmax[j] - zmin[j]);
			}
			length = norm (V+i*numObj, numObj);
			for (j=0; j<numObj; j++) {
				V[i*numObj+j] /= length;
			}
		}
		// normal line
		for (i=0; i<numObj; i++) {
			for (j=0, L[i]=1.0; j<numObj; j++) if (i != j) {
				L[i] *= (zmax[j] - zmin[j]);
			}
		}
		printf ("L=%f %f\n", L[0], L[1]);
	}
}
