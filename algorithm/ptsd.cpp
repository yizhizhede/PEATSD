#include "shape.h"
#include "population.h"
#include "algebra.h"
#include "recombination.h"
#include "terminal.h"
#include "snapshot.h"
#include "myrandom.h"
#include "parameter.h"
#include "dominate.h"
#include "problem.h"
#include "crowding.h"
#include "rank.h"
#include "mystring.h"
#include "interactive.h"
#include "tps.h"
#include "ptsd.h"
#include "model.h"
#include "bpmlp.h"
#include "cso.h"
#include "selection.h"
#include "igd.h"
#include <string.h>
#include <float.h>
#include <mpi.h>

#define MAX(a,b) ((a)>(b)?(a):(b))
#define MAX_NUM_SOLUTIONS 10000
#define OPT_PRINT 0

#define REPRODUCTION_TYPE 0	// 0: CSO (LMOCSO, default); 1: GA (NSGA-II); 2: DE (MOEA/D-DE)
#define DDS_CONSTRUCTION_TYPE 1	// 0: random construction; 1: by DVA (decision variable analysis, default)
#define DDS_MAX_DIMENSION 20	// maximum dimension of DDS (diversity design subspace, defualt 20): 1 10 20 40 100

/*************************************************************************************************************/
/**************  Main framework  *****************************************************************************/
/*************************************************************************************************************/

// TSD optimize
static void TSD_optimize (Population_t* pop);

// Main framewok of PTSD
Population_t* ptsd (Problem_t *problem) {
	Population_t* 	pop = NULL;
	int		numVar; 
	int		numObj;
	int 		comm_rank, comm_size;

	/* MPI rank */
	MPI_Comm_rank (MPI_COMM_WORLD, &comm_rank);
	MPI_Comm_size (MPI_COMM_WORLD, &comm_size);

	// 0.1 new a population
	pop 	= Population_new (problem, (Parameter_get())->popSize);
	numVar  = pop->var->colDim;
	numObj  = pop->obj->colDim;

	// 0.2 reallocate memory 
	pop->var->elements = (double *)realloc (pop->var->elements, (MAX_NUM_SOLUTIONS+10)*numVar*sizeof (double));
	pop->obj->elements = (double *)realloc (pop->obj->elements, (MAX_NUM_SOLUTIONS+10)*numObj*sizeof (double));

	// 0.3 print init pop
	if (0 == comm_rank) { isTerminal (pop); }

	// 1 TSD optimize
	TSD_optimize (pop);

	// return
	return pop;
}

/*************************************************************************************************************/
/*************** TSD optimize ********************************************************************************/
/*************************************************************************************************************/

static  Matrix_t* TSD_get_RV_OS (int rowDim, int colDim) {
	Matrix_t* 	RV = NULL;
	int		i, j, k, p;
	double		t;

	if (2 == colDim) {
		RV = Matrix_new (rowDim, 2);
		for (i=0; i<rowDim; i++) {
			RV->elements[i*2+0] = (i + 0.0) / (rowDim - 1.0);
			RV->elements[i*2+1] = (rowDim - 1.0 - i) / (rowDim - 1.0);
		}
	} else if (3 == colDim) {
		for (p=2; (p+2)*(p+1)/2 < rowDim; p++) {};
		rowDim = (p+2)*(p+1) / 2;
		RV = Matrix_new (rowDim, 3);
		for (i=0, k=0; i<p+1; i++) {
			for (j=0; j<p+1; j++) {
				if (i+j < p+1) {
					RV->elements[k*3+0] = (i + 0.0) / (p + 0.0);	
					RV->elements[k*3+1] = (j + 0.0) / (p + 0.0);	
					RV->elements[k*3+2] = (p - i - j) / (p + 0.0);	
					k++;
				}
			}
		}
	} else {
		RV = Matrix_new (rowDim, colDim);
		for (i=0; i<rowDim; i++) {
			for (j=0, t=0; j<colDim; j++) {
				RV->elements[i*colDim+j] = randu ();
				t += RV->elements[i*colDim+j]; 
			}
			for (j=0; j<colDim; j++) {
				RV->elements[i*colDim+j] /= t;
			}
		}
	}
	return RV;
}

static  Matrix_t* TSD_get_RV_DS (int rowDim, int colDim) {
	Matrix_t* 	RV = Matrix_new (rowDim, colDim);
	Matrix_t*	Q  = Matrix_new (2*rowDim, colDim);
	double		Dis[4*rowDim*rowDim+10];
	int		vis[2*rowDim+10];
	int		i, j, k, b, p1, p2;
	int		maxGen = 1000, gen = 0;
	double		child1[colDim+10], child2[colDim+10];
	double		low[colDim+10], upp[colDim+10];
	double		minDis, maxDis, t;

	// 
	if (colDim == 1) {
		for (i=0; i<rowDim; i++) {
			RV->elements[i] = i / (rowDim - 1.0);
		}
		Matrix_free (&Q);
		return RV;
	} 

	// init
	for (i=0; i<rowDim; i++) {
		for (j=0; j<colDim; j++) {
			RV->elements[i*colDim+j] = randu ();
		}
	}

	// set boundary
	for (j=0; j<colDim; j++) {
		low[j] = 0;
		upp[j] = 1;
	}

	// loop
	while (gen < maxGen) {

		// reproduce
		for (i=0; i<rowDim; i++) {
			p1 = rand () % rowDim;
			p2 = rand () % rowDim;
			realbinarycrossover(RV->elements+p1*colDim, RV->elements+p2*colDim, child1, child2, 
				1.0, colDim, low, upp);
			realmutation(child1, 1.0/colDim, colDim, low, upp);
			for (j=0; j<colDim; j++) {
				Q->elements[i*colDim+j] = child1[j];
			}
		}
		memcpy (Q->elements+rowDim*colDim, RV->elements, rowDim*colDim*sizeof (double));

		// distance
		for (i=0; i<2*rowDim; i++) {
			Dis[i*2*rowDim+i] = 0;
			for (j=i+1; j<2*rowDim; j++) {
				Dis[i*2*rowDim+j] = distance_p2p (Q->elements+i*colDim, Q->elements+j*colDim, colDim);
				Dis[j*2*rowDim+i] = Dis[i*2*rowDim+j];
			}
		}
		
		// set vis
		memset (vis, 0, 2*rowDim*sizeof (int));
		p1 = rand () % (2*rowDim);
		vis[p1] = 1;
		
		// select
		for (k=1; k<rowDim ;k++) {
			maxDis = -1.0e+100;
			b = -1;
			for (i=0; i<2*rowDim; i++) if (0 == vis[i]) {
				minDis = 1.0e+100;
				for (j=0; j<2*rowDim; j++) if (1 == vis[j]) {
					t = Dis[i*2*rowDim+j]; 
					if (t < minDis) {
						minDis = t;
					}
				}
				if (minDis > maxDis) {
					maxDis = minDis;
					b = i;
				}
			}
			if (-1 != b) {
				vis[b] = 1;
			}
		}
		
		// 
		for (i=0, k=0; i<2*rowDim; i++) if (1 == vis[i]) {
			memcpy (RV->elements+k*colDim, Q->elements+i*colDim, colDim*sizeof (double));
			k++;
		}
		
		//
		gen++;
	}
	
	Matrix_free (&Q);
	return RV;
}

/*************************************************************************************************************/
/************************** Subproblem ***********************************************************************/
/*************************************************************************************************************/
//
typedef struct Subpro_tag {
	// 	Population
	double*	var;		
	double* vel;		// velocity
	double* obj;		// 
	int	popSize;		
	int 	numVar;
	int	numObj;	

	// 	Reference Vector
	double*	V0;	// original reference vector
	double*	V;	// reference vector
	double*	gamma;	// 
	double*	L;	// normal Line of the plan with reference vectors distributing evenly.
	double*	zmin;	// objective minimum
	int	NR;	// number of NR
	int 	ADAPTRV_counter;	// counter of adapt RV
	
	// 
	int	FE;	// Function Evaluation
} Subpro_t;

//
static Subpro_t* tsdEP;		// External population
//
static Matrix_t* OS_REF_Z;	// objective space reference vector
static Matrix_t* DS_REF_V;	// decision space reference vector: DDS RV
// DDS
static int DDS_map[1000];	// map of DDS;
static int DDS_DIM;		// dimension of DDS
//
static int get_os_idx (double* obj, int numObj);	// get objective index
static int get_ds_idx (double* var, int numVar);	// get decision index
//
static Subpro_t* Subpro_new (int popSize, int numVar, int numObj);
static Subpro_t* Subpro_new (int popSize, int numVar, int numObj, int light);
static Subpro_t* Subpro_dump (Subpro_t* subpro);
//
static Subpro_t* Subpro_CSO (Population_t* pop, Subpro_t* subpro);
static Subpro_t* Subpro_GA (Population_t* pop, Subpro_t* subpro);
static Subpro_t* Subpro_DE (Population_t* pop, Subpro_t* subpro);
static void  	Subpro_select_by_RV (Population_t* pop, Subpro_t* subpro);	// Reference Vector-Guided Selection
static void  	Subpro_adapt_RV (Subpro_t* subpro);				// Reference Vector Adaptation Strategy
//
static void	Subpro_addInd (Subpro_t* subpro, double* var, double* vel, double* obj);
static void 	Subpro_initpop (Population_t* pop, Subpro_t** subpro, int idx);	
static void 	Subpro_evolve (Population_t* pop, Subpro_t** subpro, int idx);	
static void 	Subpro_free (Subpro_t** subpro);			
//
static void 	Subpro_comm  (Subpro_t** subpro, int NSP);			// communication
static void 	Subpro_learn (Subpro_t** subpro, int idx, int NSP);		// learning 
//
//*************************************************************************************************************/
//
static int get_os_idx (double* obj, int numObj) {	// get objective index
	int	i, idx;
	double	angle, minAng;

	idx	 = 0;
	minAng = vector_angle (obj, OS_REF_Z->elements, numObj);
	for (i=1; i<OS_REF_Z->rowDim; i++) {
		angle = vector_angle (obj, OS_REF_Z->elements+i*numObj, numObj);
		if (angle < minAng) {
			idx = i;
			minAng = angle;	
		}
	}
	return idx;
}

static int get_ds_idx (double* var, int numVar) {	// get decision index
	double*	lowBound = Problem_getLowerBound ();
	double*	uppBound = Problem_getUpperBound ();
	int 	i, j, idx;
	double 	distance, minDis;
	double	X[numVar+10];
	
	for (i=0; i<DDS_DIM; i++) {
		j = DDS_map[i];
		X[i] = (var[j] - lowBound[j]) / (uppBound[j] - lowBound[j]);
	}

	idx = 0;
	minDis = distance_p2p (X, DS_REF_V->elements, DDS_DIM);
	for (i=1; i<DS_REF_V->rowDim; i++) {
		distance = distance_p2p (X, DS_REF_V->elements+i*DDS_DIM, DDS_DIM);
		if (distance < minDis) {
			idx = i;
			minDis = distance;
		}
	}
	return idx + OS_REF_Z->rowDim;	// start from OS_REF_Z->rowDim
}

static void subpro_set_RV (Subpro_t* subpro) {
	int	popSize	= subpro->popSize;
	int	numObj	= subpro->numObj;
	int	i, j, k, NR, p;
	double	t, angle;

	// V, V0, NR
	if (2 == numObj) {
		NR = popSize;	
		if (NULL == subpro->V0) subpro->V0 = (double*) malloc ((NR+1)*numObj*sizeof (double));
		if (NULL == subpro->V) subpro->V = (double*) malloc ((NR+1)*numObj*sizeof (double));
		for (i=0; i<NR; i++) {
			subpro->V[i*2+0] = i / (NR - 1.0);	
			subpro->V[i*2+1] = (NR - 1.0 - i) / (NR - 1.0);	
		}
		memcpy (subpro->V0, subpro->V, NR*numObj*sizeof (double));
		subpro->NR = NR;
	} else if (3 == numObj) {
		for (p=2; (p+2)*(p+1)/2 < popSize; p++) {};
		NR = (p+2)*(p+1)/2;
		if (NULL == subpro->V0) subpro->V0 = (double*) malloc ((NR+1)*numObj*sizeof (double));
		if (NULL == subpro->V) subpro->V = (double*) malloc ((NR+1)*numObj*sizeof (double));
		for (i=0, k=0; i<p+1; i++) {
			for (j=0; j<p+1; j++)  {
				if (i+j < p+1) {
					subpro->V[k*3+0] = (i + 0.0) / p;
					subpro->V[k*3+1] = (j + 0.0) / p;
					subpro->V[k*3+2] = (p - i - j + 0.0) / p;
					k++;
				}
			}
		}
		memcpy (subpro->V0, subpro->V, NR*numObj*sizeof (double));
		subpro->NR = NR;
	} else {
		NR = popSize; 
		if (NULL == subpro->V0) subpro->V0 = (double*) malloc ((NR+1)*numObj*sizeof (double));
		if (NULL == subpro->V) subpro->V = (double*) malloc ((NR+1)*numObj*sizeof (double));
		for (i=0; i<NR; i++) {
			for (j=0, t=0; j<numObj; j++) {
				subpro->V[i*numObj+j] = randu ();
				t += subpro->V[i*numObj+j]; 
			}
			for (j=0; j<numObj; j++) {
				subpro->V[i*numObj+j] /= t;
			}
		}
		memcpy (subpro->V0, subpro->V, NR*numObj*sizeof (double));
		subpro->NR = NR;
	}

	// gamma
	if (NULL == subpro->gamma) subpro->gamma = (double*) malloc (NR*sizeof (double));
	for (i=0; i<NR; i++) { subpro->gamma[i] = 1.0e+100; }
	for (i=0; i<NR-1; i++) {
		for (j=i+1; j<NR; j++) {
			angle = vector_angle (subpro->V+i*numObj, subpro->V+j*numObj, numObj);
			if (angle < subpro->gamma[i]) 
				subpro->gamma[i] = angle;
			if (angle < subpro->gamma[j]) 
				subpro->gamma[j] = angle;
		}
	}
	
	// L, zmin
	if (NULL == subpro->L) subpro->L = (double*) malloc (numObj*sizeof (double));
	if (NULL == subpro->zmin) subpro->zmin = (double*) malloc (numObj*sizeof (double));
	for (i=0; i<numObj; i++) {
		subpro->L[i] = 1.0;
		subpro->zmin[i] = 1.0e+100;
	}
}

static Subpro_t* Subpro_new (int popSize, int numVar, int numObj) {
	Subpro_t* 	subpro = NULL;

	// calloc for subpro
	subpro = (Subpro_t*) calloc (1, sizeof (Subpro_t));

	// calloc for Population
	subpro->var 	= (double*) calloc (popSize*numVar, sizeof (double));
	subpro->vel 	= (double*) calloc (popSize*numVar, sizeof (double));
	subpro->obj 	= (double*) calloc (popSize*numObj, sizeof (double));
	subpro->popSize	= popSize;
	subpro->numVar 	= numVar;
	subpro->numObj 	= numObj;

	// set Subpro_RV
	subpro_set_RV (subpro);

	// set Function Evaluation
	subpro->FE = 0;
	
	// set popSize
	subpro->popSize = 0;

	// return
	return subpro;
}

static Subpro_t* Subpro_new (int popSize, int numVar, int numObj, int light) {
	Subpro_t* 	subpro = NULL;

	// subpro
	subpro = (Subpro_t*) calloc (1, sizeof (Subpro_t));

	// Population 
	subpro->var 	= (double*) calloc (popSize*numVar, sizeof (double));
	subpro->vel 	= (double*) calloc (popSize*numVar, sizeof (double));
	subpro->obj 	= (double*) calloc (popSize*numObj, sizeof (double));
	subpro->popSize	= popSize;
	subpro->numVar 	= numVar;
	subpro->numObj 	= numObj;

	return subpro;
}

static Subpro_t* Subpro_dump (Subpro_t* subpro) {
	Subpro_t* 	dump = NULL;
	int		popSize = subpro->popSize;
	int		numVar 	= subpro->numVar;
	int		numObj  = subpro->numObj;

	dump = Subpro_new (popSize, numVar, numObj, 0);	

	memcpy (dump->var, subpro->var, popSize*numVar*sizeof (double));
	memcpy (dump->vel, subpro->vel, popSize*numVar*sizeof (double));
	memcpy (dump->obj, subpro->obj, popSize*numObj*sizeof (double));

	return dump;
}

static Subpro_t* Subpro_CSO (Population_t* pop, Subpro_t* subpro) {
	double*		lowBound = Problem_getLowerBound ();
	double*		uppBound = Problem_getUpperBound ();
	int 		popSize	= subpro->popSize;
	int		numVar  = subpro->numVar;
	int		numObj  = subpro->numObj;
	Subpro_t* 	child = NULL;
	int		nnp = 0;	// number of new particles (nnp);
	Matrix_t*	M   = NULL;
	Matrix_t*	Obj = NULL;
	int*		I   = NULL;
	int 		queue[popSize+10], n=0;
	int		loser, winner;
	int 		i, j, k;

	// set queue
	for (i=0, n=0; i<popSize; i++) { queue[n++] = i; }
	
	// get rank 
	M = Matrix_new (popSize, numObj);
	memcpy (M->elements, subpro->obj, popSize*numObj*sizeof (double));
	Obj = Matrix_norm (M);
	I = rank_by_density (Obj);

	// new a child
	child = Subpro_new (popSize+2, numVar, numObj, 0); 

	// loop 
	while (n > 0) {
		// get loser and winner
		if (1 == n) {
			loser  = queue[0]; winner = queue[0]; n--;
		} else {
			// loser
			i = rand() % n; loser = queue[i]; queue[i] = queue[n-1]; n--;

			// winner
			i = rand() % n; winner = queue[i]; queue[i] = queue[n-1]; n--;
			
			// make sure winner is better 
			for (i=0; i<popSize; i++) if (I[i] == winner) break; 
			for (j=0; j<popSize; j++) if (I[j] == loser) break; 
			if (i > j) {
				k = loser; loser = winner; winner = k;	
			}
		}

		// update loser 
		cso (subpro->var+loser*numVar, subpro->vel+loser*numVar, subpro->var+winner*numVar, 
			child->var+nnp*numVar, child->vel+nnp*numVar, lowBound, uppBound, numVar);

		// mutation loser
		realmutation(child->var+nnp*numVar, 1.0/numVar, numVar, lowBound, uppBound);

		// evaluate
		Problem_evaluate (child->var+nnp*numVar, numVar, child->obj+nnp*numObj, numObj);
		nnp++;

		// copy winner 
		memcpy (child->vel+nnp*numVar, subpro->vel+winner*numVar, numVar*sizeof (double));
		memcpy (child->var+nnp*numVar, subpro->var+winner*numVar, numVar*sizeof (double));
		
		// mutation loser
		realmutation(child->var+nnp*numVar, 1.0/numVar, numVar, lowBound, uppBound);

		// evaluate
		Problem_evaluate (child->var+nnp*numVar, numVar, child->obj+nnp*numObj, numObj);
		nnp++;
	}
	// set popSize
	child->popSize = nnp;

	// free
	free (I); Matrix_free (&M); Matrix_free (&Obj);
	
	// return
	return child;
}

static Subpro_t* Subpro_GA (Population_t* pop, Subpro_t* subpro) {
	double*		lowBound = Problem_getLowerBound ();
	double*		uppBound = Problem_getUpperBound ();
	int 		popSize	= subpro->popSize;
	int		numVar  = subpro->numVar;
	int		numObj  = subpro->numObj;
	Subpro_t* 	child = NULL;
	int		nnp = 0;	// number of new particles (nnp);
	Matrix_t*	M   = NULL;
	Matrix_t*	Obj = NULL;
	int*		I   = NULL;
	int		loser, winner;
	int 		i, j, k;

	// get rank 
	M = Matrix_new (popSize, numObj);
	memcpy (M->elements, subpro->obj, popSize*numObj*sizeof (double));
	Obj = Matrix_norm (M);
	I = rank_by_density (Obj);

	// new a child
	child = Subpro_new (popSize+2, numVar, numObj, 0); 

	// loop
	for (k=0; k<popSize; k++) {
		i = rand () % popSize;
		j = rand () % popSize;
		loser = i < j ? i : j;

		i = rand () % popSize;
		j = rand () % popSize;
		winner = i < j ? i : j;

		loser = I[loser];
		winner = I[winner];
			
		// SBX
		realbinarycrossover(subpro->var+loser*numVar, subpro->var+winner*numVar, 
					child->var+nnp*numVar, child->var+popSize*numVar, 1.0, numVar, lowBound, uppBound);
		// mutation loser
		realmutation(child->var+nnp*numVar, 1.0/numVar, numVar, lowBound, uppBound);

		// evaluate
		Problem_evaluate (child->var+nnp*numVar, numVar, child->obj+nnp*numObj, numObj);
		nnp++;
	}

	// set popSize
	child->popSize = nnp;

	// free
	free (I); Matrix_free (&M); Matrix_free (&Obj);
	
	// return
	return child;
}

static Subpro_t* Subpro_DE (Population_t* pop, Subpro_t* subpro) {
	double*		lowBound = Problem_getLowerBound ();
	double*		uppBound = Problem_getUpperBound ();
	int 		popSize	= subpro->popSize;
	int		numVar  = subpro->numVar;
	int		numObj  = subpro->numObj;
	Subpro_t* 	child = NULL;
	int		nnp = 0;	// number of new particles (nnp);
	int 		i, j, jrand;
	int		p1, p2, p3;
	double		CR = 1.0; 
	double		F  = 0.5;

	// new a child
	child = Subpro_new (popSize+2, numVar, numObj, 0); 

	// loop
	for (i=0; i<popSize; i++) {
		p1 = rand () % popSize;

		p2 = rand () % popSize;
		while (p1 == p2 && popSize > 1) { p2 = rand () % popSize; }

		p3 = rand () % popSize;
		while ((p1 == p3 || p2 == p3) && popSize > 2) { p3 = rand () % popSize; }

		jrand = rand () % numVar;
		for (j=0; j<numVar; j++) if (randu () < CR || j == jrand) {
			child->var[nnp*numVar+j] = subpro->var[p1*numVar+j] 
						+ F * (subpro->var[p2*numVar+j] - subpro->var[p3*numVar+j]);

			if (child->var[nnp*numVar+j] < lowBound[j]) {
				child->var[nnp*numVar+j] = lowBound[j]; 
			}
			if (child->var[nnp*numVar+j] > uppBound[j]) {
				child->var[nnp*numVar+j] = uppBound[j]; 
			}
		} else {
			child->var[nnp*numVar+j] = subpro->var[p1*numVar+j];
		}
		
		// mutation loser
		realmutation(child->var+nnp*numVar, 1.0/numVar, numVar, lowBound, uppBound);

		// evaluate
		Problem_evaluate (child->var+nnp*numVar, numVar, child->obj+nnp*numObj, numObj);
		nnp++;
	}

	// set popSize
	child->popSize = nnp;

	// return
	return child;
}


static void Subpro_select_by_RV (Population_t* pop, Subpro_t* subpro) {
	int	popSize = subpro->popSize;
	int	numObj	= subpro->numObj;
	int	numVar	= subpro->numVar;
	int	NR	= subpro->NR;
	double*	V	= subpro->V;
	double*	gamma	= subpro->gamma;
	double*	L	= subpro->L;
	double*	zmin	= subpro->zmin;
	double*	obj	= subpro->obj;
	double	angle, minAngle;
	double 	APD, minAPD, length;
	double 	associate[popSize+10];
	double	beta;
	int	vis[NR+10];
	int	sel[popSize+10];
	double	f[popSize*numObj+10];
	int	comm_rank, comm_size;
	Subpro_t* dump = NULL;
	int 	i, j, k, a, b;

	//
	if (popSize < 2) return;

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

	// dump & copy & free
	dump = Subpro_dump (subpro);
	for (i=0, k=0; i<popSize; i++) if (1 == sel[i]) {
		memcpy (subpro->var+k*numVar, dump->var+i*numVar, numVar*sizeof (double));	
		memcpy (subpro->vel+k*numVar, dump->vel+i*numVar, numVar*sizeof (double));	
		memcpy (subpro->obj+k*numObj, dump->obj+i*numObj, numObj*sizeof (double));	
		k++;
	}
	subpro->popSize = k;
	Subpro_free (&dump);
}

//
static void Subpro_adapt_RV (Subpro_t* subpro) {
	double*	obj 	= subpro->obj;
	int	popSize = subpro->popSize;
	int	numObj	= subpro->numObj;
	int	NR	= subpro->NR;
	double*	V0	= subpro->V0;
	double*	V	= subpro->V;
	double*	L	= subpro->L;
	double*	gamma	= subpro->gamma;
	int	comm_rank, comm_size;
	double	zmin[numObj+10]; 
	double 	zmax[numObj+10];
	double 	beta, length, angle;
	int 	i, j; 

	// MPI
	MPI_Comm_rank (MPI_COMM_WORLD, &comm_rank);
	MPI_Comm_size (MPI_COMM_WORLD, &comm_size);

	// calculate beta
	beta = (1.0 * comm_size * Problem_getFitness ()) / Problem_getLifetime ();
	beta = (beta > 1.0) ? 1.0 : beta;

	if (beta > 0.1 * subpro->ADAPTRV_counter) {
		subpro->ADAPTRV_counter++;
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
		// gamma
		for (i=0; i<NR; i++) { gamma[i] = 1.0e+100; }
		for (i=0; i<NR-1; i++) {
			for (j=i+1; j<NR; j++) {
				angle = vector_angle (V+i*numObj, V+j*numObj, numObj);
				if (angle < gamma[i]) 
					gamma[i] = angle;
				if (angle < gamma[j]) 
					gamma[j] = angle;
			}
		}
		// normal line
		for (i=0; i<numObj; i++) {
			for (j=0, L[i]=1.0; j<numObj; j++) if (i != j) {
				L[i] *= (zmax[j] - zmin[j]);
			}
		}
		// printf ("L=%f %f\n", L[0], L[1]);
	}
}

static void Subpro_free (Subpro_t** subpro) {
	if (NULL == subpro || NULL == (*subpro)) return;
	if (NULL != (*subpro)->var) free ((*subpro)->var);
	if (NULL != (*subpro)->vel) free ((*subpro)->vel);
	if (NULL != (*subpro)->obj) free ((*subpro)->obj);
	if (NULL != (*subpro)->V) free ((*subpro)->V);
	if (NULL != (*subpro)->L) free ((*subpro)->L);
	if (NULL != (*subpro)) free ((*subpro));
	(*subpro) = NULL;
}

static void Subpro_addInd (Subpro_t* subpro, double* var, double* vel, double* obj) {
	int	popSize = subpro->popSize;
	int 	numVar 	= subpro->numVar;
	int 	numObj 	= subpro->numObj;

	//
	subpro->var = (double*) realloc (subpro->var, (popSize+2)*numVar*sizeof (double));
	subpro->vel = (double*) realloc (subpro->vel, (popSize+2)*numVar*sizeof (double));
	subpro->obj = (double*) realloc (subpro->obj, (popSize+2)*numObj*sizeof (double));

	//
	memcpy (subpro->var+popSize*numVar, var, numVar*sizeof (double));
	memcpy (subpro->obj+popSize*numObj, obj, numObj*sizeof (double));
	if (NULL == vel) {
		memset (subpro->vel+popSize*numVar, 0, numVar*sizeof (double));
	} else {
		memcpy (subpro->vel+popSize*numVar, vel, numVar*sizeof (double));
	}

	// 
	subpro->popSize++;
}

static void Subpro_initpop (Population_t* pop, Subpro_t** subpro, int idx) {
	double*		lowBound = Problem_getLowerBound ();
	double*		uppBound = Problem_getUpperBound ();
	int 		numVar 	= subpro[idx]->numVar;
	int 		numObj 	= subpro[idx]->numObj;
	int		NR 	= subpro[idx]->NR;
	Subpro_t*	child 	= NULL;
	double		C[DDS_DIM+10];	// center
	double		V[DDS_DIM+10];	// random vector
	double		X[DDS_DIM+10];	// X = C + V
	double		r = 1.0e+100; 		// radius
	double		distance, t; 
	int		i, j, k;

	// use pop
	for (i=0; i<pop->obj->rowDim; i++) {
		j = get_os_idx (pop->obj->elements+i*numObj, numObj);	
		k = get_ds_idx (pop->var->elements+i*numVar, numVar);	
		if (j == idx || k == idx) {
			Subpro_addInd (subpro[idx], pop->var->elements+i*numVar, NULL, pop->obj->elements+i*numObj);
		}
	}
	if (idx < OS_REF_Z->rowDim) return;

	// set center: C
	k = idx - OS_REF_Z->rowDim;
	memcpy (C, DS_REF_V->elements+k*DDS_DIM, DDS_DIM*sizeof (double));

	// set radius: r
	for (i=0; i<DS_REF_V->rowDim; i++) if (i != k) {
		distance = distance_p2p (C, DS_REF_V->elements+i*DDS_DIM, DDS_DIM);
		if (distance < r) {
			r = distance;
		}
	}
	r /= 2.0;

	// new a child
	child = Subpro_new (NR, numVar, numObj, 0);

	// init child
	for (i=0; i<NR; i++) {
		for (j=0; j<numVar; j++) {
			child->var[i*numVar+j] = lowBound[j] + randu()*(uppBound[j]-lowBound[j]);
		}
		for (k=0, t=0; k<DDS_DIM; k++) {
			V[k] = 2 * randu () - 1;
			t += V[k]*V[k];
		}
		t = sqrt (t);
		for (k=0; k<DDS_DIM; k++) {
			V[k] = randu() * r * V[k] / t;
			X[k] = C[k] + V[k];	// X = C + V
			if (X[k] < 0) X[k] = 0;
			if (X[k] > 1) X[k] = 1;
			j = DDS_map[k];
			child->var[i*numVar+j] = lowBound[j] + X[k]*(uppBound[j]-lowBound[j]);
		}
		Problem_evaluate (child->var+i*numVar, numVar, child->obj+i*numObj, numObj);
	}

	// use child
	for (i=0; i<NR; i++) {
		j = get_os_idx (child->obj+i*numObj, numObj);	
		k = idx;
		Subpro_addInd (subpro[j], child->var+i*numVar, NULL, child->obj+i*numObj);
		Subpro_addInd (subpro[k], child->var+i*numVar, NULL, child->obj+i*numObj);
	}
	
	// free child
	Subpro_free (&child);
}

//
static void Subpro_evolve (Population_t* pop, Subpro_t** subpro, int idx) {
	int		popSize = subpro[idx]->popSize;
	int 		numVar 	= subpro[idx]->numVar;
	int 		numObj 	= subpro[idx]->numObj;
	Subpro_t* 	child = NULL;
	int		i, j, k;

	// no individual
	if (popSize < 1) return;
	
	/********************* Reproduction *******************/

	// only the first NR individuals participate in reproduction
	if (popSize > subpro[idx]->NR) { subpro[idx]->popSize = subpro[idx]->NR; }

	// reproduction by specific-operator
	switch (REPRODUCTION_TYPE) {
		case 0:
			child = Subpro_CSO (pop, subpro[idx]);	break; 	// CSO (LMOCSO)
		case 1:
			child = Subpro_GA (pop, subpro[idx]);	break;	// GA (NSGA-II)
		case 2: 
			child = Subpro_DE (pop, subpro[idx]);	break;	// DA (MOEA/D-DE)
		default:
			child = Subpro_CSO (pop, subpro[idx]);	break;	// CSO (LMOCSO)
	}

	// recover popSize
	subpro[idx]->popSize = popSize;

	/********************* Use Child  **********************/
	for (i=0; i<child->popSize; i++) {
		j = get_os_idx (child->obj+i*numObj, numObj);	
		k = get_ds_idx (child->var+i*numVar, numVar);	
		Subpro_addInd (subpro[j], child->var+i*numVar, child->vel+i*numVar, child->obj+i*numObj);
		Subpro_addInd (subpro[k], child->var+i*numVar, child->vel+i*numVar, child->obj+i*numObj);
		Subpro_addInd (tsdEP, child->var+i*numVar, child->vel+i*numVar, child->obj+i*numObj);

		/********************* Environment Selection *******************/
		if (subpro[j]->popSize >= 2*subpro[j]->NR) {
			Subpro_select_by_RV (pop, subpro[j]);	// Reference Vector-Guided Selection
			Subpro_adapt_RV (subpro[j]);		// Reference Vector Adaptation Strategy
		}
		if (subpro[k]->popSize >= 2*subpro[k]->NR) {
			Subpro_select_by_RV (pop, subpro[k]);	// Reference Vector-Guided Selection
			Subpro_adapt_RV (subpro[k]);		// Reference Vector Adaptation Strategy
		}
		if (tsdEP->popSize >= 2*tsdEP->NR) {
			Subpro_select_by_RV (pop, tsdEP);	// Reference Vector-Guided Selection
			Subpro_adapt_RV (tsdEP);		// Reference Vector Adaptation Strategy
		}
	}

	// free the child
	Subpro_free (&child);
}

// Communication of Process
static int comm_topology[1000*4]; 
static int comm_isLoad;
//
static void Subpro_comm (Subpro_t** subpro, int NSP) {
	int		popSize = subpro[0]->popSize;
	int		numObj  = subpro[0]->numObj;
	int		numVar  = subpro[0]->numVar;
	int		NR	= subpro[0]->NR;
	int 		comm_rank, comm_size;
	MPI_Request	request;
	double*		buff_send = NULL;
	double*		buff_recv = NULL;
	int		dest, source, r;
	char		fn[128];
	FILE*		fp = NULL;
	int		i, count, block, n;
	int		b1, b2, b3, b4;

	// MPI rank and size
	MPI_Comm_rank (MPI_COMM_WORLD, &comm_rank);
	MPI_Comm_size (MPI_COMM_WORLD, &comm_size);

	// load topology
	if (0 == comm_isLoad) {
		comm_isLoad = 1;
		sprintf (fn, "topology/Von_Neumann_topology_%06d", comm_size);
		fp = fopen (fn, "r");
		if (NULL == fp) { printf ("file: (%s) does not exit\n", fn); exit (0);}
		for (i=0; i<comm_size; i++) {
			if (-1 == fscanf (fp, "%d %d %d %d",
				comm_topology+i*4+0, comm_topology+i*4+1, comm_topology+i*4+2, comm_topology+i*4+3)) {
				printf ("file: (%s) is not completed\n", fn); exit (0);
			}
		}
		fclose (fp);
	}

	// destination & source
	r = rand () % 4;
	MPI_Bcast (&r, 1, MPI_INT, 0, MPI_COMM_WORLD);
	dest   = comm_topology[comm_rank*4 + r];
	source = comm_topology[comm_rank*4 + (r + 2) % 4];

	//	block size 
	b1 	= 0;
	b2 	= b1 + 1;
	b3 	= b2 + NR*numVar;
	b4 	= b3 + NR*numVar;
	block 	= 1 + NR*numVar + NR*numVar + NR*numObj;
	count 	= NSP * block;

	// malloc buffer
	buff_send = (double*) malloc (count*sizeof (double));
	buff_recv = (double*) malloc (count*sizeof (double));

	// buff_send
	for (i=0; i<NSP; i++) {
		popSize = (subpro[i]->popSize < NR) ? subpro[i]->popSize : NR;
		buff_send[i*block+b1] = popSize;
		if (0 == popSize) continue;
		memcpy (buff_send+i*block+b2, subpro[i]->var, popSize*numVar*sizeof (double));
		memcpy (buff_send+i*block+b3, subpro[i]->vel, popSize*numVar*sizeof (double));
		memcpy (buff_send+i*block+b4, subpro[i]->obj, popSize*numObj*sizeof (double));
	}

	// send 
	MPI_Isend (buff_send, count, MPI_DOUBLE, dest, 0, MPI_COMM_WORLD, &request);

	// recv
	MPI_Recv (buff_recv, count, MPI_DOUBLE, source, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
	
	// Wait
	MPI_Wait (&request, MPI_STATUS_IGNORE);

	// Barrier
	MPI_Barrier (MPI_COMM_WORLD);

	// buff_recv
	for (i=0; i<NSP; i++) {
		popSize = buff_recv[i*block+b1];
		if (0 == popSize) continue;

		// update subproblem
	 	n = subpro[i]->popSize;
		subpro[i]->var = (double*) realloc (subpro[i]->var, (n+popSize+1)*numVar*sizeof (double));
		subpro[i]->vel = (double*) realloc (subpro[i]->vel, (n+popSize+1)*numVar*sizeof (double));
		subpro[i]->obj = (double*) realloc (subpro[i]->obj, (n+popSize+1)*numObj*sizeof (double));
		memcpy (subpro[i]->var+n*numVar, buff_recv+i*block+b2, popSize*numVar*sizeof (double));
		memcpy (subpro[i]->vel+n*numVar, buff_recv+i*block+b3, popSize*numVar*sizeof (double));
		memcpy (subpro[i]->obj+n*numObj, buff_recv+i*block+b4, popSize*numObj*sizeof (double));
		subpro[i]->popSize = n + popSize;
		if (subpro[i]->popSize >= 2*subpro[i]->NR) {
			Subpro_select_by_RV (NULL, subpro[i]);
			Subpro_adapt_RV (subpro[i]);
		}

		// update external population
	 	n = tsdEP->popSize;
		tsdEP->var = (double*) realloc (tsdEP->var, (n+popSize+1)*numVar*sizeof (double));
		tsdEP->vel = (double*) realloc (tsdEP->vel, (n+popSize+1)*numVar*sizeof (double));
		tsdEP->obj = (double*) realloc (tsdEP->obj, (n+popSize+1)*numObj*sizeof (double));
		memcpy (tsdEP->var+n*numVar, buff_recv+i*block+b2, popSize*numVar*sizeof (double));
		memcpy (tsdEP->vel+n*numVar, buff_recv+i*block+b3, popSize*numVar*sizeof (double));
		memcpy (tsdEP->obj+n*numObj, buff_recv+i*block+b4, popSize*numObj*sizeof (double));
		tsdEP->popSize = n + popSize;
		if (tsdEP->popSize >= 2*tsdEP->NR) {
			Subpro_select_by_RV (NULL, tsdEP);
			Subpro_adapt_RV (tsdEP);
		}
	}

	// free buffer
	free (buff_send);
	free (buff_recv);
}

//
static int SL_isLearn (double* student, double* teacher, int numObj) {
	int	flag;

	flag = isDominate (student, teacher, numObj);
	if (flag == 1 || flag == 0) { return 0; }
	return 1;
}

//
static void Subpro_learn (Subpro_t** subpro, int idx, int NSP) {
	double*		lowBound = Problem_getLowerBound ();
	double*		uppBound = Problem_getUpperBound ();
	int		popSize	= subpro[idx]->popSize;
	int		numVar  = subpro[idx]->numVar;
	int		numObj  = subpro[idx]->numObj;
	int		NR	= subpro[idx]->NR;
	int		PRO[NSP+10], np=0;
	int		IND[NR+100], ni=0;
	Subpro_t* 	child = NULL;
	int		nnp =0; 
	int		i, j, k, r, flag = 0;
	int 		loser, winner;
	int		a, p3;

	// no individual
	if (popSize < 1) return; 

	/********************* Reproduction *******************/

	// new a child
	child = Subpro_new (popSize+2, numVar, numObj, 0);

	// loop: randomly select a winner for each loser
	for (loser=0; loser<subpro[idx]->popSize && loser<NR; loser++) {	// loser
		flag = 0;	// set flag
		for (k=0, np=0; k<NSP; k++) if (idx != k) { PRO[np++] = k; }		// push pro
		while (np > 0 && 0 == flag) {	
			r = rand () % np; k = PRO[r]; PRO[r] = PRO[np-1]; np--;		// pop pro
			for (i=0, ni=0; i<subpro[k]->popSize && i<NR; i++) { IND[ni++] = i; }	// push ind
			while (ni > 0 && 0 == flag) {
				r = rand () % ni; i = IND[r]; IND[r] = IND[ni-1]; ni--;		// pop ind
				if (0 == SL_isLearn (subpro[idx]->obj+loser*numObj,subpro[k]->obj+i*numObj,numObj)) continue;
	
				// set winner
				flag 	= 1;
				winner 	= i;

				// update loser	by specific-operator 
				switch (REPRODUCTION_TYPE) {		
					case 0: 
						cso (subpro[idx]->var+loser*numVar, subpro[idx]->vel+loser*numVar,
							subpro[k]->var+winner*numVar, 
							child->var+nnp*numVar, child->vel+nnp*numVar, 
							lowBound, uppBound, numVar);
						break;		// CSO (LMOCSO)
					case 1:
						realbinarycrossover(subpro[idx]->var+loser*numVar, 
							subpro[k]->var+winner*numVar, 
							child->var+nnp*numVar, child->var+popSize*numVar, 
							1.0, numVar, lowBound, uppBound);
						break;		// GA (NSGA-II)
					case 2:
						p3 = rand () % popSize;
						while (loser == p3 && popSize > 1) { p3 = rand () % popSize; }

						for (a=0; a<numVar; a++) {
							child->var[nnp*numVar+a] = subpro[idx]->var[loser*numVar+a] 
								+ 0.5*(subpro[k]->var[winner*numVar+a] 
								- subpro[idx]->var[p3*numVar+a]);

							if (child->var[nnp*numVar+a] < lowBound[a]) {
								child->var[nnp*numVar+a] = lowBound[a]; 
							}
							if (child->var[nnp*numVar+a] > uppBound[a]) {
								child->var[nnp*numVar+a] = uppBound[a]; 
							}
						}
						break;		// DE (MOEA/D-DE) with CR = 1.0 and F = 0.5
					default:
						cso (subpro[idx]->var+loser*numVar, subpro[idx]->vel+loser*numVar,
							subpro[k]->var+winner*numVar, 
							child->var+nnp*numVar, child->vel+nnp*numVar, 
							lowBound, uppBound, numVar);
						break;		// CSO (LMOCSO)
				}

				// mutation loser
				realmutation(child->var+nnp*numVar, 1.0/numVar, numVar, lowBound, uppBound);

				// evaluate loser
				Problem_evaluate (child->var+nnp*numVar, numVar, child->obj+nnp*numObj, numObj);

				// increase nnp
				nnp += 1;
			}
		}
	}

	// no individual
	if (0 == nnp) { Subpro_free (&child); return; }

	// set popSize
	child->popSize = nnp;
	
	/********************* Use Child  **********************/
	for (i=0; i<child->popSize; i++) {
		j = get_os_idx (child->obj+i*numObj, numObj);	
		k = get_ds_idx (child->var+i*numVar, numVar);	
		Subpro_addInd (subpro[j], child->var+i*numVar, child->vel+i*numVar, child->obj+i*numObj);
		Subpro_addInd (subpro[k], child->var+i*numVar, child->vel+i*numVar, child->obj+i*numObj);
		Subpro_addInd (tsdEP, child->var+i*numVar, child->vel+i*numVar, child->obj+i*numObj);

		/********************* Environment Selection *******************/
		if (subpro[j]->popSize >= 2*subpro[j]->NR) {
			Subpro_select_by_RV (NULL, subpro[j]);	// Reference Vector-Guided Selection
			Subpro_adapt_RV (subpro[j]);		// Reference Vector Adaptation Strategy
		}
		if (subpro[k]->popSize >= 2*subpro[k]->NR) {
			Subpro_select_by_RV (NULL, subpro[k]);	// Reference Vector-Guided Selection
			Subpro_adapt_RV (subpro[k]);		// Reference Vector Adaptation Strategy
		}
		if (tsdEP->popSize >= 2*tsdEP->NR) {
			Subpro_select_by_RV (NULL, tsdEP);	// Reference Vector-Guided Selection
			Subpro_adapt_RV (tsdEP);		// Reference Vector Adaptation Strategy
		}
	}
	
	// free the child
	Subpro_free (&child);
}

/*************************************************************************************************************/
/*************************************************************************************************************/
/*************************************************************************************************************/

static void TSDCOLLECT_remove_one (Population_t* pop) {
	int 	popSize = pop->var->rowDim;
	int 	numVar	= pop->var->colDim;
	int 	numObj	= pop->obj->colDim;
	double*	var	= pop->var->elements;
	double*	obj	= pop->obj->elements;
	double	SDE[popSize+10], minSDE, t, d;	
	double	maxObj[numObj+10];
	int	maxIdx[numObj+10];
	int	i, j, k, flag;
	
	// find the dominated solution
	for (i=0; i<popSize; i++) {
		for (j=0; j<popSize; j++) if (i != j) {
			flag = isDominate (obj+j*numObj, obj+i*numObj, numObj);
			if (1 == flag || 0 == flag) {
				k = pop->var->rowDim - 1;	
				if (i != k) {		
					memcpy (var+i*numVar, var+k*numVar, numVar*sizeof (double));
					memcpy (obj+i*numObj, obj+k*numObj, numObj*sizeof (double));
				}
				pop->var->rowDim = k;
				pop->obj->rowDim = k;
				return;	
			}
		}
	}

	// find the extreme value
	for (j=0; j<numObj; j++) { 
		maxObj[j] = obj[j]; 
		maxIdx[j] = 0;
		for (i=1; i<popSize; i++) {
			if (obj[i*numObj+j] > maxObj[j]) {
				maxObj[j] = obj[i*numObj+j];
				maxIdx[j] = i;
			}
		}
	}

	// counter SDE
	for (i=0; i<popSize; i++) {
		SDE[i] = 1.0e+100;
		for (j=0; j<popSize; j++) if (i != j) {
			for (k=0, d=0; k<numObj; k++) {
				t = obj[j*numObj+k] - obj[i*numObj+k];
				if (t > 0) { d += t*t; }
			}
			// d = sqrt (d);
			if (d < SDE[i]) { SDE[i] = d; }
		}
	}
	
	// protect the extreme value
	for (j=0; j<numObj; j++) {
		SDE[maxIdx[j]] = 1.0e+100;
	}
	
	// find the minSDE
	minSDE 	= SDE[0];
	i 	= 0;
	for (k=1; k<popSize; k++) if (SDE[k] < minSDE) {
		minSDE 	= SDE[k];
		i	= k;
	}
	
	// remove the ith individual
	k = pop->var->rowDim - 1;	
	if (i != k) {		
		memcpy (var+i*numVar, var+k*numVar, numVar*sizeof (double));
		memcpy (obj+i*numObj, obj+k*numObj, numObj*sizeof (double));
	}
	pop->var->rowDim = k;
	pop->obj->rowDim = k;
}

static void TSD_collect (Population_t* pop, Subpro_t** subpro, int NSP) {
	int	popSize = subpro[0]->popSize;
	int	numVar 	= subpro[0]->numVar;
	int	numObj 	= subpro[0]->numObj;
	int	NR	= subpro[0]->NR;
	int	b1, b2, b3, block;
	int	comm_rank, comm_size;
	double*	buff_send = NULL;
	double*	buff_recv = NULL;
	int	i, j, k, a;

	// MPI rank and size
	MPI_Comm_rank (MPI_COMM_WORLD, &comm_rank);
	MPI_Comm_size (MPI_COMM_WORLD, &comm_size);

	// block	
	b1	= 0;
	b2	= 1;
	b3	= 1 + NR*numVar;
	block 	= 1 + NR*numVar + NR*numObj;	

	// calloc
	buff_send = (double*) calloc (NSP*block, sizeof (double));
	buff_recv = (double*) calloc (NSP*block, sizeof (double));

	for (i=comm_rank; i<NSP; i+=comm_size) {
		popSize = (subpro[i]->popSize < NR) ? subpro[i]->popSize : NR;
		buff_send[i*block+b1] = popSize;	
		memcpy (buff_send+i*block+b2, subpro[i]->var, popSize*numVar*sizeof (double));
		memcpy (buff_send+i*block+b3, subpro[i]->obj, popSize*numObj*sizeof (double));
	}

	// MPI Reduce
	MPI_Reduce (buff_send, buff_recv, NSP*block, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);

	if (0 == comm_rank) {
		for (i=0, k=0; i<NSP; i++) {
			popSize = buff_recv[i*block+b1];	
			if (popSize < 1) continue;
			memcpy (pop->var->elements+k*numVar, buff_recv+i*block+b2, popSize*numVar*sizeof (double));
			memcpy (pop->obj->elements+k*numObj, buff_recv+i*block+b3, popSize*numObj*sizeof (double));
			k += popSize;

			if (OPT_PRINT) {
				printf("SP%d=[\n", i);
				for (a=0; a<popSize; a++) {
					for (j=0; j<numObj; j++) {
						printf ("%.16f ", buff_recv[i*block+b3+a*numObj+j]);
					}
					printf ("\n");
				}
				printf("];\n");
				printf("scatter(SP%d(:,1), SP%d(:,2));\n", i, i);
			}
		}
		pop->var->rowDim = k;
		pop->obj->rowDim = k;

		if (OPT_PRINT) {
			printf ("popSize=%d / %d\n", k, NSP*NR);
			printf("A=[\n");
			Matrix_print (pop->obj);
			printf("];\n");
			printf("scatter(A(:,1), A(:,2));\n");
		}

		// remove_one
		while (pop->var->rowDim > (Parameter_get())->popSize) {
			TSDCOLLECT_remove_one (pop);
		}
	}

	// free 
	free (buff_send);
	free (buff_recv);
}


static void TSD_collect (Population_t* pop, Subpro_t* tsdEP) {
	int	popSize = tsdEP->popSize;
	int	numVar 	= tsdEP->numVar;
	int	numObj 	= tsdEP->numObj;
	int	maxSize	= (Parameter_get())->popSize;
	int	b1, b2, b3, block;
	int	comm_rank, comm_size;
	double*	buff_send = NULL;
	double*	buff_recv = NULL;
	int	i, j, k, a;

	// MPI rank and size
	MPI_Comm_rank (MPI_COMM_WORLD, &comm_rank);
	MPI_Comm_size (MPI_COMM_WORLD, &comm_size);

	// block	
	b1	= 0;
	b2	= 1;
	b3	= 1 + maxSize*numVar;
	block 	= 1 + maxSize*numVar + maxSize*numObj;	

	// calloc
	buff_send = (double*) calloc (block, sizeof (double));
	buff_recv = (double*) calloc (comm_size*block, sizeof (double));

	popSize = (popSize <= maxSize) ? popSize : maxSize;
	buff_send[b1] = popSize;	
	memcpy (buff_send+b2, tsdEP->var, popSize*numVar*sizeof (double));
	memcpy (buff_send+b3, tsdEP->obj, popSize*numObj*sizeof (double));

	// MPI Reduce
	MPI_Gather (buff_send, block, MPI_DOUBLE, buff_recv, block, MPI_DOUBLE, 0, MPI_COMM_WORLD);

	if (0 == comm_rank) {
		for (i=0, k=0; i<comm_size; i++) {
			popSize = buff_recv[i*block+b1];	
			if (popSize < 1) continue;
			memcpy (pop->var->elements+k*numVar, buff_recv+i*block+b2, popSize*numVar*sizeof (double));
			memcpy (pop->obj->elements+k*numObj, buff_recv+i*block+b3, popSize*numObj*sizeof (double));
			k += popSize;

			if (OPT_PRINT) {
				printf("EP%d=[\n", i);
				for (a=0; a<popSize; a++) {
					for (j=0; j<numObj; j++) {
						printf ("%.16f ", buff_recv[i*block+b3+a*numObj+j]);
					}
					printf ("\n");
				}
				printf("];\n");
				printf("scatter(EP%d(:,1), EP%d(:,2));\n", i, i);
			}
		}
		pop->var->rowDim = k;
		pop->obj->rowDim = k;

		if (OPT_PRINT) {
			printf ("popSize=%d / %d\n", k, comm_size*maxSize);
			printf("A=[\n");
			Matrix_print (pop->obj);
			printf("];\n");
			printf("scatter(A(:,1), A(:,2));\n");
		}

		// remove_one
		while (pop->var->rowDim > (Parameter_get())->popSize) {
			TSDCOLLECT_remove_one (pop);
		}
	}

	// free 
	free (buff_send);
	free (buff_recv);
}

/*** 
 * serial function
 * Out: DDS_map, DDS_DIM
 ***/
static void TSD_construct_DDS (Population_t* pop) {
	double*	lowBound = Problem_getLowerBound ();
	double*	uppBound = Problem_getUpperBound ();
	int	popSize	= pop->var->rowDim;
	int	numObj  = pop->obj->colDim;
	int	numVar  = pop->var->colDim;
	int	queue[numVar+10], n=0;
	int	opposite[numVar+10];	
	double	X[numVar+10];
	double	F[numObj+10];
	int	i, j, k, r;
	int	positive=0, negative=0, zero=0; 
	double	t;

	if (0 == DDS_CONSTRUCTION_TYPE) {	
		// 0. construct randomly
		for (i=0, k=0; i<DDS_MAX_DIMENSION; i++) {
			DDS_map[k++] = rand () % numVar;
		}
		DDS_DIM = k;	
	} else {
		// 1. construct by decision variable analysi (DVA)
		for (i=0; i<numVar; i++) {
			// 1.1 mutation
			memcpy (X, pop->var->elements, numVar*sizeof (double));
			realmutation(X+i, 1.0, 1, lowBound+i, uppBound+i);
			Problem_evaluate (X, numVar, F, numObj);

			// 1.2 check
			positive = 0; negative = 0; zero = 0;
			for (j=0; j<numObj; j++) {
				t = pop->obj->elements[j] - F[j];
				if (t > 0) positive++;
				else if (t < 0) negative++;
				else zero++;
			}

			// 1.3 opposite
			opposite[i] = (zero >= numObj - 1) ? 1 : 0;

			// 1.4 distance variable
			if (positive > 0 && negative == 0) {
				memcpy (pop->var->elements, X, numVar*sizeof (double));
				memcpy (pop->obj->elements, F, numObj*sizeof (double));
				continue;
			} 

			// 1.5 position varialbe
			if (positive > 0 && negative > 0) {
				queue[n++] = i;
				popSize = pop->var->rowDim;
				memcpy (pop->var->elements+popSize*numVar, X, numVar*sizeof (double));
				memcpy (pop->obj->elements+popSize*numObj, F, numObj*sizeof (double));
				pop->var->rowDim++;
				pop->obj->rowDim++;
			}
		}
		if (0 == n) for (i=0; i<numVar; i++) if (0 == opposite[i]) { queue[n++] = i; }
		if (0 == n) for (i=0; i<numVar; i++) { queue[n++] = i; }

		// 1.6 select randomly 
		k = 0;
		while (k<DDS_MAX_DIMENSION && n > 0) {
			r = rand () % n;
			DDS_map[k++] = queue[r];
			queue[r] = queue[n-1];
			n--;
		}
		DDS_DIM = k;
	}
}

static void print_info () {
	int	i;

	switch (REPRODUCTION_TYPE) {
		case 0: printf ("REPRODUCTION_TYPE: CSO\n"); break;
		case 1: printf ("REPRODUCTION_TYPE: GA\n"); break;
		case 2: printf ("REPRODUCTION_TYPE: DA\n"); break;
	}
	
	if (DDS_CONSTRUCTION_TYPE) {
		printf ("DDS_CONSTRUCTION_TYPE: DVA\n");
	} else {
		printf ("DDS_CONSTRUCTION_TYPE: Random\n");
	}

	printf ("DDS(%d) = [ ", DDS_DIM);
	for (i=0; i<DDS_DIM; i++) {
		printf ("%d ", DDS_map[i]);
	}
	printf ("]\n\n");
}

static void TSD_optimize (Population_t* pop) {
	int		numObj  = pop->obj->colDim;
	int		numVar  = pop->var->colDim;
	int		comm_rank, comm_size;
	int		fitness; 
	int		FE = 0,	maxFE = 1;
	int		PRINT_counter = 1;
	int		i, k;

	//		Subproblems 
	int		NSP = 20;		// Number of Subproblem: 10 20 40 80 160	(default: 20)
	int		NIS = 10;		// Number of Individual in each Subspace 	(default: 10)
	int		NGL = 20;		// Number of Generation in loop: 1 10 20 40 80 	(default: 20)
	Subpro_t*	subpro[2000];

	// 0.0 MPI rank and size
	MPI_Comm_rank (MPI_COMM_WORLD, &comm_rank);
	MPI_Comm_size (MPI_COMM_WORLD, &comm_size);

	// 0.1 new a external population
	tsdEP = Subpro_new ((Parameter_get())->popSize, numVar, numObj);

	// 0.2 construct DDS; OUT: DDS_map, DDS_DIM 
	if (0 == comm_rank) { TSD_construct_DDS (pop); }
	MPI_Bcast (&DDS_DIM, 1, MPI_INT, 0, MPI_COMM_WORLD);
	MPI_Bcast (DDS_map, DDS_DIM, MPI_INT, 0, MPI_COMM_WORLD);

	// print information
	if (0 == comm_rank) { print_info (); }

	// 0.3 RV (OS_REF_Z) of objective space 
	OS_REF_Z = TSD_get_RV_OS (NSP/2, numObj);

	// 0.4 RV (DS_REF_V) of decision space 
	if (0 == comm_rank) { DS_REF_V = TSD_get_RV_DS (NSP/2, DDS_DIM); }
	else { DS_REF_V = Matrix_new (NSP/2, DDS_DIM);	}
	MPI_Bcast (DS_REF_V->elements, DS_REF_V->rowDim*DDS_DIM, MPI_DOUBLE, 0, MPI_COMM_WORLD);

	// 0.5 update NSP
	NSP = OS_REF_Z->rowDim + DS_REF_V->rowDim;

	// print information
	if (0 == comm_rank) {
		printf ("NSP=%d (os:%d, ds:%d); NIS = %d; NGL = %d, NC = %d\n", 
			NSP, OS_REF_Z->rowDim, DS_REF_V->rowDim, NIS, NGL, comm_size);
	}
	
	// 1.0 New Subpro 
	for (i=0; i<NSP; i++) { subpro[i] = Subpro_new (NIS, numVar, numObj); }
	
	// 1.1 Subpro init pop
	for (i=comm_rank; i<NSP; i+=comm_size) { Subpro_initpop (pop, subpro, i); }

	// 2. loop
	while (FE < maxFE) {
		// 2.1 Evolution
		for (i=comm_rank; i<NSP; i+=comm_size) {
			for (k=0; k<NGL; k++) { Subpro_evolve (pop, subpro, i); }
		}
		
		// 2.2 Communication
		Subpro_comm (subpro, NSP);

		// 2.3 Learn
		for (i=comm_rank; i<NSP; i+=comm_size) {
			Subpro_learn (subpro, i, NSP);
		}

		// 2.4 get FE & maxFE
		fitness	= Problem_getFitness ();
		MPI_Allreduce (&fitness, &FE, 1, MPI_INT, MPI_SUM, MPI_COMM_WORLD);
		maxFE 	= Problem_getLifetime ();
		if ((FE + 0.0)/maxFE >= PRINT_counter / 20.0) {
			PRINT_counter++;
			TSD_collect (pop, tsdEP); 	// collect
			if (0 == comm_rank) { snapshot_click (pop); }
		}
	} // end loop

	// collect
	TSD_collect (pop, subpro, NSP);	
	if (0 == comm_rank) { 
		if (igd (pop->obj, (Problem_get())->title) < pop->IGD ) {
			snapshot_click (pop); 
		}
	}

	// return
	return;
}
