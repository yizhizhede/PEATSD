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
#include "vldf.h"
#include "model.h"
#include "bpmlp.h"
#include <string.h>
#include <float.h>

#define MAX(a,b) ((a)>(b)?(a):(b))
#define MAX_NUM_SOLUTIONS 10000
#define OPT_PRINT 0
#define GRP_PRINT 0

/************ Aggregation Function ***************************************************************************/
static double g_sum (double *f, double *lambda, int len) {
	return sum (f, len);
}

/*************************************************************************************************************/
/**************  Main framework  *****************************************************************************/
/*************************************************************************************************************/

static void perturb_analysis_variables_before_optimization (Population_t* pop);		// Perturb before optimization
static void perturb_analysis_variables_after_optimization (Population_t* pop);		// Perturb after optimization 
static void SLPSO_optimize (Population_t* pop, int* mask, double (*g_func)(double *f, double *w, int M), double *gW);// SLPSO
static void TPS_optimize (Population_t* pop, double* bx, double* by, int* mask, double (*g_func)(double *f, double *w, int M), double *gW);	// TPS
static void next_position_variables (Population_t *pop);				// Next 
static void satisfy_conditions_R (Population_t*pop, double *x);				// Satisfy Conditions R
static void group_print (Population_t* pop);						// group print

// Main framewok of VLDF
Population_t* vldf (Problem_t *problem) {
	double*		lowBound = Problem_getLowerBound ();
	double*		uppBound = Problem_getUpperBound ();
	Population_t* 	pop = NULL;
	int		num_for_model = 10;
	int		numVar, numObj;
	int		j;
	double 		value; 

/****************************************************************************************************************/
/****************************************************************************************************************/
/****************************************************************************************************************/

	// 0.1 new a population
	pop = Population_new (problem, (Parameter_get())->popSize);
	numVar  = pop->var->colDim;
	numObj  = pop->obj->colDim;

	// 0.2 reallocate memory 
	pop->var->elements = (double *)realloc (pop->var->elements, (MAX_NUM_SOLUTIONS+10)*numVar*sizeof (double));
	pop->obj->elements = (double *)realloc (pop->obj->elements, (MAX_NUM_SOLUTIONS+10)*numObj*sizeof (double));

	// 0.3 snapshot
	snapshot_click (pop);

/***************  1. Decision Variable Analysis ******************************************************************/

	// 1.1 perturb and analysis before optimization 
	perturb_analysis_variables_before_optimization (pop);

	// 1.2. optimize and perturb
	if (!pop->I_flag) {
		// 1.2.1 SLPOS Optimize
		SLPSO_optimize (pop, NULL, g_sum, NULL);

		// 1.2.2 perturb after optimization 
		perturb_analysis_variables_after_optimization (pop);

		// 1.2.3 snapshot
		snapshot_click (pop);
	}
	
	// 1.3 group print
	group_print (pop);		

/*************** 2. Optimize with Modal **********************************************************************/

	// 2. Optimize with Modal
	while (pop->cursor < MAX_NUM_SOLUTIONS && 0 == isTerminal (pop)) {
		// 2.1 next position variables
		next_position_variables (pop);

		// 2.2 optimize distance variables
		SLPSO_optimize (pop, pop->I, g_sum, NULL);

		// 2.3 update model
		if (pop->cursor == num_for_model) {
			model_update (pop);
		} 
	}

	// 2.4 update model
	if (pop->cursor != num_for_model) {
		model_update (pop);
	}

/*************** 3. Prediction Using the Modal **********************************************************************/

	// 3. prediction using the model.
	while (pop->cursor < MAX_NUM_SOLUTIONS) {
		// 3.1 next position variables
		next_position_variables (pop);

		// 3.2 prediction
		for (j=0; j<numVar; j++) if (pop->I[j]) {
			// 3.2.1 get value from model
			value = model_getValue (pop, j, NULL);
			pop->var->elements[pop->cursor*numVar+j] = value;

			// 3.2.2 check boundary
			if (pop->var->elements[pop->cursor*numVar+j] > uppBound[j]) {
				pop->var->elements[pop->cursor*numVar+j] = uppBound[j];
			}
			if (pop->var->elements[pop->cursor*numVar+j] < lowBound[j]) {
				pop->var->elements[pop->cursor*numVar+j] = lowBound[j];
			}
		}

		// 3.3 satisfy conditions of R
		satisfy_conditions_R (pop, pop->var->elements+pop->cursor*numVar);

		// 3.4 evaluate 
		Problem_evaluate(pop->var->elements+pop->cursor*numVar,numVar,pop->obj->elements+pop->cursor*numObj,numObj);

		// 3.5 move cursor
		pop->cursor++;

		// 3.6 resize popsize 
		if (pop->cursor > pop->var->rowDim) {
			pop->var->rowDim = pop->cursor;
			pop->obj->rowDim = pop->cursor;
		}
	}
	
	// 3.6 snapshot
	snapshot_click (pop);

	// 4. return pop
	return pop;
}


/*************************************************************************************************************/
/******************  Minimum Spanning Tree   *****************************************************************/
/*************************************************************************************************************/

#define 	MST_MAX_NUM 500
static int 	MST_C;					// counter of side
static int 	MST_S[MST_MAX_NUM+10][2];		// side 
static double 	MST_W[MST_MAX_NUM+10]; 			// weight
static double 	MST_DIS[MST_MAX_NUM+10][MST_MAX_NUM+10];// distance
static int 	MST_DIS_C;				// counter of distance

static void MST_DIS_update (Population_t *pop) {
	Matrix_t*	Obj = pop->obj;
	int		numObj  = pop->obj->colDim;
	int		popSize = pop->cursor;
	int 		i, j;
	double 		t;

	if (MST_DIS_C == 0) {
		for (i=0; i<popSize-1; i++) {
			for (j=i+1; j<popSize; j++) {
				t = distance_p2p (Obj->elements+i*numObj, Obj->elements+j*numObj, numObj);
				MST_DIS[i][j] = t;
				MST_DIS[j][i] = t;
			}
		}
	} else {
		for (i=MST_DIS_C; i<popSize; i++) {
			for (j=0; j<MST_DIS_C; j++) {
				t = distance_p2p (Obj->elements+i*numObj, Obj->elements+j*numObj, numObj);
				MST_DIS[i][j] = t;
				MST_DIS[j][i] = t;
			}
		}
	}
	MST_DIS_C = popSize;
}

static void MST_update (Population_t *pop) {
	int		popSize = pop->cursor;
	int 		vis[popSize+10];
	int		i, j, k, c;
	int		v1, v2;
	double		w, t;

	// set vis
	memset (vis, 0, popSize*sizeof (int));

	// update distance
	MST_DIS_update (pop);

	if (MST_C < 1) {
		vis[0] = 1;
		for (k=popSize-1; k>0;  k--) {
			w = 1.0e+100;
			v1 = v2 = -1;
			for (i=0; i<popSize; i++) if (0 == vis[i]) {
				for (j=0; j<popSize; j++) if (1 == vis[j]) {
					t = MST_DIS[i][j];	// distance
					if (t < w) {
						w = t;
						v1 = i;
						v2 = j;
					}
				}
			}
			vis[v1] = 1;
			MST_S[MST_C][0] = v1;
			MST_S[MST_C][1] = v2;
			MST_W[MST_C] = w;
			MST_C++;
		}
	} else {
		for (c=0; c<MST_C; c++) {
			v1 = MST_S[c][0];
			v2 = MST_S[c][1];
			vis[v1] = 0;
			vis[v2] = 1;

			w = 1.0e+100;
			v1 = v2 = -1;
			i = popSize - 1; 
			for (j=0; j<popSize; j++) if (1 == vis[j]) {
				t = MST_DIS[i][j];	// distance
				if (t < w) {
					w = t;
					v1 = i;
					v2 = j;
				}
			}
			if (w < MST_W[c]) {
				vis[v1] = 1;
				MST_S[c][0] = v1;
				MST_S[c][1] = v2;
				MST_W[c] = w;
				MST_C = c + 1;
				break;
			} else {
				v1 = MST_S[c][0];
				vis[v1] = 1;
			}
		}
			
		for (k=popSize-1-MST_C; k>0;  k--) {
			w = 1.0e+100;
			v1 = v2 = -1;
			for (i=0; i<popSize; i++) if (0 == vis[i]) {
				for (j=0; j<popSize; j++) if (1 == vis[j]) {
					t = MST_DIS[i][j];	// distance
					if (t < w) {
						w = t;
						v1 = i;
						v2 = j;
					}
				}
			}
			vis[v1] = 1;
			MST_S[MST_C][0] = v1;
			MST_S[MST_C][1] = v2;
			MST_W[MST_C] = w;
			MST_C++;
		}
	}
}

static void MST_getLongestSide (int &v1, int &v2) {
	int 	i, k;
	double 	w;

	w = MST_W[0];
	k = 0;
	for (i=1; i<MST_C; i++) {
		if (MST_W[i] > w) {
			w = MST_W[i];
			k = i;
		}
	}
	v1 = MST_S[k][0];
	v2 = MST_S[k][1];
}

/*************************************************************************************************************/
/******************  Next Position Variable  *****************************************************************/
/*************************************************************************************************************/

static void next_position_variables (Population_t *pop) {
	Matrix_t*	Var = pop->var;
	int		numVar  = pop->var->colDim;
	double*		lowBound = Problem_getLowerBound ();
	double*		uppBound = Problem_getUpperBound ();
	int		i, j, a, b; 
	double		diff;
	double		p1[numVar], p2[numVar], c1[numVar], c2[numVar], lb[numVar], ub[numVar];
	int		r1, r2, n;

	if (pop->cursor < 5) {
		// random generate 
		for (j=0; j<numVar; j++) if (0 == pop->I[j]) {
			Var->elements[pop->cursor*numVar+j] = lowBound[j] + randu()*(uppBound[j] - lowBound[j]);
		}
	} else if (pop->cursor < MST_MAX_NUM) {
		// update MST, and get Longest Side
		MST_update (pop);
		MST_getLongestSide (a, b);

		// half
		for (j=0; j<numVar; j++) if (0 == pop->I[j]) {
			Var->elements[pop->cursor*numVar+j] = (Var->elements[a*numVar+j] + Var->elements[b*numVar+j]) / 2;
		}
	} else {
		// prepare for SBX and PM	
		r1 = rand() % pop->cursor;	
		r2 = rand() % pop->cursor;	
		for (j=0, n=0; j<numVar; j++) if (0 == pop->I[j]) {
			p1[n] = Var->elements[r1*numVar+j];
			p2[n] = Var->elements[r2*numVar+j];
			lb[n] = lowBound[j];
			ub[n] = uppBound[j];
			n++;
		}
		
		// SBX and PM
		realbinarycrossover(p1, p2, c1, c2, 1.0, n, lb, ub);
		realmutation(c1, 1.0/n, n, lb, ub);		

		// use SBX and PM
		for (j=0, n=0; j<numVar; j++) if (0 == pop->I[j]) {
			Var->elements[pop->cursor*numVar+j] = c1[n];
			n++;

			// check boundary
			if (Var->elements[pop->cursor*numVar+j] < lowBound[j]) {
				Var->elements[pop->cursor*numVar+j] = lowBound[j];
			}
			if (Var->elements[pop->cursor*numVar+j] > uppBound[j]) {
				Var->elements[pop->cursor*numVar+j] = uppBound[j];
			}
		}
	}

	// set all position variables to 0
	if (pop->cursor == 5) for (j=0; j<numVar; j++) if (0 == pop->I[j]) {
		Var->elements[pop->cursor*numVar+j] = lowBound[j];
	}

	// set all position variables to 1
	if (pop->cursor == 6) for (j=0; j<numVar; j++) if (0 == pop->I[j]) {
		Var->elements[pop->cursor*numVar+j] = uppBound[j];
	}

	// set one of position variables to 1, the other to 0
	for (j=0, n=0; j<numVar; j++) if (0 == pop->I[j]) n++;	
	if (n > 1 && pop->cursor >= 20 && pop->cursor < (20 + n%10)) {
		for (j=0; j<numVar; j++) if (0 == pop->I[j]) {
			Var->elements[pop->cursor*numVar+j] = lowBound[j];
		}
		for (j=0, i=0; j<numVar; j++) if (0 == pop->I[j]) {
			if (i == (pop->cursor % 10)) {
				Var->elements[pop->cursor*numVar+j] = uppBound[j];
				break;
			}
			i++;
		}
	}

	// check if repeat
	for (i=pop->cursor-1; i>=0 && pop->cursor < MST_MAX_NUM; i--) {
		for (j=0, diff=0; j<numVar; j++) if (0 == pop->I[j]) {
			diff += fabs (Var->elements[pop->cursor*numVar+j] - Var->elements[i*numVar+j]);	
		}
		if (diff > 0)	continue;
		for (j=0; j<numVar; j++) if (0 == pop->I[j]) {
			Var->elements[pop->cursor*numVar+j] = lowBound[j] + randu()*(uppBound[j] - lowBound[j]);
		}
		break;
	}

	// generate randomly 
	if (pop->cursor > 100 && pop->cursor < MST_MAX_NUM && randu () < 0.1) {
		for (j=0; j<numVar; j++) if (0 == pop->I[j]) {
			Var->elements[pop->cursor*numVar+j] = lowBound[j] + randu()*(uppBound[j] - lowBound[j]);
		}

	}
}

/*************************************************************************************************************/
/**************  LPSO Optimze ********************************************************************************/
/*************************************************************************************************************/

static void SLPSO_init_pop (Population_t* pop, int* mask, double* X, int m, int n) {
	double*	lowBound = Problem_getLowerBound ();
	double*	uppBound = Problem_getUpperBound ();
	int	numVar  = pop->var->colDim;
	int	from_previous = 10;
	int 	i, j;
	double 	value, offset;

	// mask = 1
	for (i=0; i<m; i++) {
		for (j=0; j<n; j++) if (1 == mask[j]){
			X[i*n+j] = lowBound[j] + randu()*(uppBound[j]-lowBound[j]);
		}
	}

	// from previous solution 
	for (i=0; i<from_previous && i<pop->cursor; i++) {
		for (j=0; j<n; j++) if (1 == mask[j]){
			X[i*n+j] = pop->var->elements[i*numVar+j];
		}
	}

	// from model
	for (i=from_previous; i<m; i+=2) {
		for (j=0; j<n; j++) if (1 == mask[j]) {
			// get value from model
			value = model_getValue (pop, j, &offset);

			// set jth decision variables
			X[i*n+j] = value + (2*randu()-1)*offset;

			// check boundary
			if (X[i*n+j] > uppBound[j]) {
				X[i*n+j] = uppBound[j];
			}
			if (X[i*n+j] < lowBound[j]) {
				X[i*n+j] = lowBound[j];
			}
		}
	}

	// mask = 0
	for (i=0; i<m; i++) {
		for (j=0; j<n; j++) if (0 == mask[j]) {
			X[i*n+j] = pop->var->elements[pop->cursor*numVar+j];
		}
	}

#if (1 == OPT_PRINT)
	printf ("init pop\n");
	for (i=0; i<m; i++) {
		for (j=0; j<5 && j<n; j++) {
			printf ("%f ", X[i*n+j]);
		}
		printf ("\n");
	}
#endif
}

static double	SIT_VARIANCE[10] = {1, 2, 3};
static int	SIT_i = 0;
static int SLPSO_is_terminal (double *F, int m, int t) {
	int 	i = SIT_i;

	if ((t / m) % 20  == 0) {
		SIT_VARIANCE[i] = VAR (F, m);
		SIT_i = (i+1) % 3;

		if (fabs(2*SIT_VARIANCE[0] - SIT_VARIANCE[1] - SIT_VARIANCE[2]) < DBL_EPSILON) {
			SIT_VARIANCE[0] = 1; SIT_VARIANCE[1] = 2; SIT_VARIANCE[2] = 3;
			return 1;
		}
		if (SIT_VARIANCE[0] < DBL_EPSILON || SIT_VARIANCE[1] < DBL_EPSILON || SIT_VARIANCE[2] < DBL_EPSILON) {
			SIT_VARIANCE[0] = 1; SIT_VARIANCE[1] = 2; SIT_VARIANCE[2] = 3;
			return 1;
		}
	}
	return 0;
}

// SLPSO Optimze
static void SLPSO_optimize (Population_t* pop, int* mask, double (*g_func)(double *f, double *w, int M), double *gW) {
	double*		lowBound = Problem_getLowerBound ();
	double*		uppBound = Problem_getUpperBound ();
	int		numVar  = pop->var->colDim;
	int		numObj	= pop->obj->colDim;
	int 		i, j, k, a;
	int		maxFEs = (int)Problem_getLifetime () / 10;
	int		mask_flag = 0;
	int 		old_I[numVar+10];

	//		paramters of SL-PSO
	int 		n = numVar;		// number of variables
	int 		t = 0;
	int 		M = 100; 
	double 		alpha=0.5, belta=0.01;
	int 		m = M + n / 10;		// population size 
	double 		epsilon = belta * n / M;
	double 		PL[m+10]; 
	double 		F[m+10];
	double*		X = (double *)malloc (m*n*sizeof (double));
	double*		V = (double *)calloc (m*n, sizeof (double));
	double*		Y = (double *)calloc (m*numObj, sizeof (double));
	double 		best_solution_x[numVar+10];
	double 		best_solution_y[numObj+10];
	double		Iij, Cij, X_bar[n+10], r1, r2, r3;
	Matrix_t*	T = Matrix_new (m, 1);
	int*		index = NULL;

/*************************************************************************************************************/

	// if mask == NULL
	if (NULL == mask) {
		mask_flag = 1;
		mask = (int *)malloc ((numVar+10)*sizeof (int));
		for (i=0; i<numVar; i++) { 	
			mask[i] = 1; 
			old_I[i] = pop->I[i];
			pop->I[i] = 1;
		}
	}

	// set best_solution_y
	for (i=0; i<numObj; i++) {
		best_solution_y[i] = 1.0e+100;
	}

	// set PL
	for (i=0; i<m; i++) {
		PL[i] = pow(1.0 - 1.0*i/m, alpha*log(ceil(1.0*n/M)));
	}

	// init pop 
	SLPSO_init_pop (pop, mask, X, m, n);

/*************************************************************************************************************/

	// main loop
	while (t < maxFEs) {
		// fitness evaluation
		for (i=0; i<m; i++) {
			// make X+i satisfy conditions of R
			satisfy_conditions_R (pop, X+i*numVar);		

			// evaluate 
			Problem_evaluate (X+i*numVar, numVar, Y+i*numObj, numObj);
			t++;
		}

		// aggregation
		for (i=0; i<m; i++) {
			F[i] = sum (Y+i*numObj, numObj);
		}

		// sort
		memcpy (T->elements, F, m*sizeof (double));
		index = sort (T, (char *)"DES");

		// update best solution using Y
		r1 = sum (Y+index[m-1]*numObj, numObj);
		r2 = sum (best_solution_y, numObj);
		if (r1 < r2 ) {
			memcpy (best_solution_x, X+index[m-1]*numVar, numVar*sizeof (double));
			memcpy (best_solution_y, Y+index[m-1]*numObj, numObj*sizeof (double));
		#if (1 == OPT_PRINT)
			printf ("cursor=%d; Fitness=%.16e; t=%d/%d; SLPSO\n", pop->cursor, r1, t, maxFEs);
		#endif
		}
	
		// is terminal
		if (SLPSO_is_terminal (F, m, t) || t >= maxFEs) { 
			free (index);
			break;	
		}

/***************** update X **************************************************************************************/

		// set X_bar
		mean (X, m, numVar, X_bar);

		// update X_i
		for (a=0; a<m-1; a++) if (randu () < PL[a]) {
			i = index[a];
			for (j=0; j<n; j++) {
				k = rand()%(m-a-1) + (a+1);
				k = index[k];	
				Iij = X[k*n+j] - X[i*n+j];
				Cij = X_bar[j] - X[i*n+j];
				r1 = randu ();
				r2 = randu ();
				r3 = randu ();
				V[i*n+j] = r1*V[i*n+j] + r2*Iij + r3*epsilon*Cij;
				X[i*n+j] = X[i*n+j] + V[i*n+j];
				if (X[i*n+j] > uppBound[j]) {
					X[i*n+j] = uppBound[j];
				}
				if (X[i*n+j] < lowBound[j]) {
					X[i*n+j] = lowBound[j];
				}
			}
		}

		// free index
		free (index);
	}

/*************************************************************************************************************/

	// TPS
	TPS_optimize (pop, best_solution_x, best_solution_y, mask, g_func, gW);

#if (1 == OPT_PRINT)
	printf ("cursor=%d; Fitness=%.16e; t=%d/%d; TPS\n", pop->cursor, sum (best_solution_y, numObj), t, maxFEs);
#endif

/*************************************************************************************************************/

	// extra the best solution
	memcpy (pop->var->elements + pop->cursor*numVar, best_solution_x, numVar*sizeof (double));
	memcpy (pop->obj->elements + pop->cursor*numObj, best_solution_y, numObj*sizeof (double));
	pop->cursor++;

	// set popsize
	if (pop->cursor > pop->var->rowDim) {
		pop->var->rowDim = pop->cursor;
		pop->obj->rowDim = pop->cursor;
	}

/*************************************************************************************************************/

	// free mask
	if (1 == mask_flag) { 
		free (mask); 
		for (i=0; i<numVar; i++) {
			pop->I[i] = old_I[i];
		}
	}

	// free T
	Matrix_free (&T);

	// free X, V, Y
	free (X); free (V); free (Y);
}

/*************************************************************************************************************/
/**************  Perturb All Variables ***********************************************************************/
/*************************************************************************************************************/

static void compute_R (Population_t* pop, Matrix_t* Y, int NP) {
	int		numVar = pop->var->colDim;
	int		numObj = pop->obj->colDim;
	double		L1[(NP+10)*numObj];
	double		L2[(NP+10)*numObj];
	double		L3[(NP+10)*numObj];
	double		x[NP+10], y[NP+10];
	int		i, j, k, m, n;

	// 5. compute R 
	for (i=0; i<numVar; i++) { 	
		pop->R[i*numVar+i] = 7;
		for (j=i+1; j<numVar; j++) {
			memcpy (L1, Y->elements+i*NP*numObj, NP*numObj*sizeof(double));
			memcpy (L2, Y->elements+j*NP*numObj, NP*numObj*sizeof(double));
			for (k=NP*numObj-1; k>=0; k--) {
				L3[k] = L1[k] - L2[k];			// L3 = L1 - L2
			}
	
			// 5.1 check if L1 = L2
			if (norm (L3, NP*numObj) < FLT_EPSILON) {
				pop->R[i*numVar+j] = 7;
				pop->R[j*numVar+i] = 7;
				continue;
			}
				
			// 5.2 check if L2 = a*L1 + b
			for (m=0, n=0; m<numObj; m++) {
				for (k=0; k<NP; k++) {
					x[k] = L1[k*numObj+m];
					y[k] = L2[k*numObj+m];
				}
				n += isLinear (x, y, NP);
			}
			if (n >= numObj) {
				pop->R[i*numVar+j] += 2;
				pop->R[j*numVar+i] += 2;
			}

			// 5.3 check if L3 = L1 - L2 = t*A + B
			for (m=0, n=0; m<numObj; m++) {
				for (k=0; k<NP; k++) {
					x[k] = k+1;
					y[k] = L3[k*numObj+m];
				}
				n += isLinear (x, y, NP);
			}
			if (n >= numObj) {
				pop->R[i*numVar+j] += 1;
				pop->R[j*numVar+i] += 1;
			}
		}
	}
}

static void compute_CBO (Population_t* pop, Matrix_t* Y, int NP) {
	int		numVar = pop->var->colDim;
	int		numObj = pop->obj->colDim;
	double		L1[(NP+10)*numObj];
	double		L2[(NP+10)*numObj];
	double 		ratio;
	int		i, j, k, a;

	// compute CBO 
	for (i=0; i<numVar; i++) {

		// get L1
		memcpy (L1, Y->elements+i*NP*numObj, NP*numObj*sizeof (double));

		// set L2
		for (k=0; k<NP-1; k++) {
			for (j=0; j<numObj; j++) {
				L2[k*numObj+j] = L1[(k+1)*numObj+j] - L1[k*numObj+j];
			}
		}
		
		pop->CBO[i] = 0;
		pop->CBO_posi[i] = 0;
		pop->CBO_nega[i] = 0;
		pop->CBO_zero[i] = 0;
		for (k=0; k<NP-1; k++) {
			for (j=0; j<numObj-1; j++) {
				for (a=j+1; a<numObj; a++) {
					if (fabs (L2[k*numObj+j])  > DBL_EPSILON) {
						ratio = L2[k*numObj+a] / L2[k*numObj+j];
						if (fabs(ratio) > 1) {
							ratio = 1.0 / ratio;
						}
					} else if (fabs (L2[k*numObj+a])  > DBL_EPSILON){
						ratio = L2[k*numObj+j] / L2[k*numObj+a]; 
						if (fabs(ratio) > 1) {
							ratio = 1.0 / ratio;
						}
					} else {
						ratio = 0;
					}
					pop->CBO[i] += ratio;

					if (L2[k*numObj+a] > DBL_EPSILON && L2[k*numObj+j] > DBL_EPSILON) {
						pop->CBO_posi[i]++;
					} else if (L2[k*numObj+a] < -DBL_EPSILON && L2[k*numObj+j] < -DBL_EPSILON) {
						pop->CBO_posi[i]++;
					} else if (L2[k*numObj+a] > DBL_EPSILON && L2[k*numObj+j] < -DBL_EPSILON) {
						pop->CBO_nega[i]++;
					} else if (L2[k*numObj+a] < -DBL_EPSILON && L2[k*numObj+j] > DBL_EPSILON) {
						pop->CBO_nega[i]++;
					} else {
						pop->CBO_zero[i]++;
					}
				}
			}
		}
	}
}

static double array_max(double *array,int len) {
        double 	t=array[len-1];
        int 	i;

        for (i=len-2; i>=0; i--) {
                if (array[i] > t) {
                        t = array[i];
		}
        }
        return t;
}

static double gamma_func(double d) {
     double muM = FLT_EPSILON /2.0;
     return (d * muM)/(1 - (d * muM));
}
     

static Matrix_t* gd2 (int *Queue, int C) {
	int 		i, j, a, b;
	int 		numVar = (Problem_get ()) -> numVar;
	int 		numObj = (Problem_get ()) -> numObj;
	double	 	f_base;
	Matrix_t*	f_hat = NULL;
	Matrix_t*	F = NULL;
	Matrix_t*	Lambda = NULL;
	Matrix_t*	Theta = NULL;
	double		x1[numVar+10];
	double		x2[numVar+10];
	double		m[numVar+10];
	double*		lowBound = Problem_getLowerBound ();
	double*		uppBound = Problem_getUpperBound ();
	double		buff[100], delta1, delta2;
	double		eInf, eSup, eta0=0, eta1=0, eps;

	f_hat = Matrix_new (C, 1);
	F = Matrix_new (C, C);
	Lambda = Matrix_new (C, C); 
	Theta = Matrix_new (C, C); 


	for (i=0; i<numVar; i++) {
		x1[i] = lowBound[i] +randu()*(uppBound[i] - lowBound[i]);
		m[i]  = lowBound[i] +randu()*(uppBound[i] - lowBound[i]);
	}

	// compute f_base
        Problem_evaluate (x1, numVar, buff, numObj);
	f_base = sum(buff, numObj);

	// compute f_hat
	for (a=0; a<C; a++) {
		i = Queue[a];
		memcpy (x2, x1, numVar*sizeof (double));
		x2[i] = m[i];
        	Problem_evaluate (x2, numVar, buff, numObj);
		f_hat->elements[a] = sum(buff, numObj);
	}

	// compuate F
	for (a=0; a<C-1; a++) {
		for (b=a+1; b<C; b++) {
			i = Queue[a];
			j = Queue[b];
			memcpy (x2, x1, numVar*sizeof (double));
			x2[i] = m[i];
			x2[j] = m[j];
			Problem_evaluate (x2, numVar, buff, numObj);
			F->elements[a*C+b] = sum(buff, numObj);
			F->elements[b*C+a] = F->elements[a*C+b]; 
		}
	}

	// compute Lambda: function ISM ()
	for (a=0; a<C-1; a++) {
		for (b=a+1; b<C; b++) {
			delta1 = f_hat->elements[a] - f_base;
			delta2 = F->elements[a*C+b] - f_hat->elements[b];
			Lambda->elements[a*C+b] = fabs (delta1 - delta2);
			Lambda->elements[b*C+a] = Lambda->elements[a*C+b];
		}
	}

	// compute Theta: function DSM () 
	for (i=0; i<C*C; i++) {
		Theta->elements[i] = 100;
	}
	for (a=0; a<C-1; a++) {
		for (b=a+1; b<C; b++) {
			buff[0]	= f_base;
			buff[1] = F->elements[a*C+b];
			buff[2] = f_hat->elements[a];
			buff[3] = f_hat->elements[b];

			eInf = gamma_func(2.0)*MAX(buff[0]+buff[1],buff[2]+buff[3]);
			eSup = gamma_func(sqrt(C))*array_max (buff, 4);	

			if (Lambda->elements[a*C+b] < eInf) {
				Theta->elements[a*C+b] = 0;
				Theta->elements[b*C+a] = 0;
				eta0 += 1;
			} else if (Lambda->elements[a*C+b] > eSup) {
				Theta->elements[a*C+b] = 1.0;
				Theta->elements[b*C+a] = 1.0;
				eta1 += 1;
			}
		}
	}
	for (a=0; a<C-1; a++) {
		for (b=a+1; b<C; b++) if (Theta->elements[a*C+b] > 2) {
			buff[0]	= f_base;
			buff[1] = F->elements[a*C+b];
			buff[2] = f_hat->elements[a];
			buff[3] = f_hat->elements[b];

			eInf = gamma_func(2.0)*MAX(buff[0]+buff[1],buff[2]+buff[3]);
			eSup = gamma_func(sqrt(C))*array_max (buff, 4);	
			eps  = (eta0*eInf + eta1*eSup) / (eta0 + eta1);

			if (Lambda->elements[a*C+b] > eps) {
				Theta->elements[a*C+b] = 1.0;
				Theta->elements[b*C+a] = 1.0;
			} else {
				Theta->elements[a*C+b] = 0;
				Theta->elements[b*C+a] = 0;
			}
		}
	}

	//
	for (a=0; a<C; a++) {
		Theta->elements[a*C+a] = 0;
	}

	Matrix_free (&f_hat);
	Matrix_free (&F);
	Matrix_free (&Lambda); 
	return Theta;
}

static void compute_I (Population_t* pop, Matrix_t* Y, int NP) {
	int	numVar = pop->var->colDim;
	int	numObj = pop->obj->colDim;
	int 	vis[numVar+10];
	int	i, j, k, n1, n2, n3, n4, n5, n6;
	int	Queue[numVar+10], queue[numVar+10], n = 0;

	int	SUM = pop->CBO_posi[0] + pop->CBO_nega[0] + pop->CBO_zero[0];
	int 	POSI[numVar], NEGA[numVar], ZERO[numVar]; 
	int	MODL[numVar], ISLE[numVar], NUMB[numVar], LINK[numVar];
	int	C = 0; 

	Matrix_t*	Theta = NULL;

/*************************************************************************************************************/
/************* 1.1 Color decision variables *******************************************************************/
/*************************************************************************************************************/

	memset (vis, 0, numVar*sizeof (int));

	// zero == SUM works as the first cluster/color
	for (i=0, NUMB[0] = 0; i<numVar; i++) if (0 == vis[i] && pop->CBO_zero[i] == SUM) {
		vis[i] = 1;
		POSI[0] = 0;
		NEGA[0] = 0;
		ZERO[0] = SUM;
		MODL[0] = 0;
		ISLE[0] = 1;
		NUMB[0] = NUMB[0] + 1;
		C = 1;
	}

	// other cases
	for (i=0; i<numVar; i++) if (0 == vis[i]) {
		vis[i] = 1;
		POSI[C] = pop->CBO_posi[i];
		NEGA[C] = pop->CBO_nega[i];
		ZERO[C] = pop->CBO_zero[i];
		MODL[C] = pop->M[i];
		ISLE[C] = pop->O[i];
		NUMB[C] = 1;

		for (j=i+1; j<numVar; j++) {
			if (pop->CBO_posi[j] == POSI[C] && pop->CBO_nega[j] == NEGA[C] && 
		    	pop->M[j] == MODL[C] && pop->O[j] == ISLE[C]) {
				vis[j] = 1;
				NUMB[C] = NUMB[C] + 1;
			}
		}
		C++;
	}

#if (1 == GRP_PRINT)	
	for (k=0; k<C; k++) {
		printf ("c = %2d, posi=%4d, nega=%4d, zero=%4d, modal=%d, isle=%d, number=%4d\n", 
			k, POSI[k], NEGA[k], ZERO[k], MODL[k], ISLE[k], NUMB[k]);
	}
#endif

/*************************************************************************************************************/
/**************** 1.2 Use Color  *****************************************************************************/
/*************************************************************************************************************/

	// rule 0: C == 1
	if (C == 1) {
		pop->I_flag = 1;
		for (i=0; i<numVar; i++) { 
			pop->I[i] = 1; 
		}
		return;
	} 

	// rule 1: NUMB = xxx
	for (k=0, n1 = 0; k<C; k++) if (NEGA[k] == 0) {
		n1 += NUMB[k];
	}
	if (n1 == (numVar - (numObj - 1))) {
		pop->I_flag = 1;
	#if (1 == GRP_PRINT)	
		printf ("rule 1.1: NUMB = xxx\n");
	#endif
		for (i=0; i<numVar; i++) if (pop->CBO_nega[i] == 0){
			pop->I[i] = 1;
		} else {
			pop->I[i] = 0;
		}
		return;
	}

	if (C <= numObj) {
		// rule 1: base on NUMB = numVar - (numObj - 1)
		for (k=0; k<C; k++) if (NUMB[k] == (numVar - (numObj-1))){
			break;
		}
		if (k < C) {
			pop->I_flag = 1;
			if (ZERO[k] < SUM) { 
			#if (1 == GRP_PRINT)	
				printf ("rule 1.2: NUMB = xxx\n");
			#endif
				for (i=0; i<numVar; i++) { 
					if (pop->CBO_posi[i] == POSI[k] && pop->CBO_nega[i] == NEGA[k] && 
					pop->M[i] == MODL[k] && pop->O[i] == ISLE[k]) {
						pop->I[i] = 1;
					} else {
						pop->I[i] = 0;
					}
				}
			} else {
			#if (1 == GRP_PRINT)	
				printf ("rule 1.3: NUMB = xxx\n");
			#endif
				for (i=0; i<numVar; i++) if (pop->CBO_zero[i] == SUM) {
					pop->I[i] = 1;
				} else {
					pop->I[i] = 0;
				}
			}
			return;
		}

		// rule 2: base on ISLE = 1
		for (k=0, n1 = 0; k<C; k++) {
			n1 += ISLE[k];
		}
		if (n1 == 1) {
			pop->I_flag = 1;
		#if (1 == GRP_PRINT)	
			printf ("rule 2: ISLE = 1\n");
		#endif
			for (i=0; i<numVar; i++) {
				pop->I[i] = pop->O[i];
			}
			return;
		}

		// rule 3: base on POSI = SUM
		for (k=0, n1=0; k<C; k++) if (POSI[k] == SUM){
			n1++;
		}
		if (n1 == 1) {
			pop->I_flag = 1;
		#if (1 == GRP_PRINT)	
			printf ("rule 3: POSI = SUM\n");
		#endif
			for (i=0; i<numVar; i++) if (pop->CBO_posi[i] == SUM){
				pop->I[i] = 1;
			} else {
				pop->I[i] = 0;
			}
			return;
		}
	}

/*************************************************************************************************************/
/********************* 2.1 Build Link ************************************************************************/
/*************************************************************************************************************/

	for (i=0; i<C; i++) {
		for (j=0, n=0; j<numVar; j++) {
			if (pop->CBO_posi[j] == POSI[i] && pop->CBO_nega[j] == NEGA[i] && pop->M[j] == MODL[i]) {
				queue[n++] = j;
			} else if (pop->CBO_zero[j] == SUM && SUM == ZERO[i]) {
				queue[n++] = j;
			}
		}
		Queue[i] = queue[rand()%n];
	}
	Theta = gd2 (Queue, C);
	for (i=0; i<C; i++) {
		for (j=0, LINK[i]=0; j<C; j++) {
			LINK[i] += (int)(Theta->elements[i*C+j] + 0.01);
		}
	}
	Matrix_free (&Theta);

#if (1 == GRP_PRINT)	
	for (k=0; k<C; k++) {
		printf ("c = %4d, posi=%4d, nega=%4d, zero=%4d, modal=%d, isle=%d, number=%4d, Queue=%4d, link=%4d\n", 
			k, POSI[k], NEGA[k], ZERO[k], MODL[k], ISLE[k], NUMB[k], Queue[k], LINK[k]);
	}
#endif

/*************************************************************************************************************/
/********************* 2.2 Use Link **************************************************************************/
/*************************************************************************************************************/
	
	n1 = n2 = n3 = n4 = n5 = n6 = -1;
	for (i=0, k=-1; i<C; i++) {
		if (LINK[i] > n1) {
			n1 = LINK[i];
			n2 = MODL[i];
			n3 = ISLE[i];
			n4 = NEGA[i];
			n5 = NUMB[i];
			n6 = POSI[i];
			k = i;
		} else if (LINK[i] == n1) {
			if (MODL[i] > n2) {
				n2 = MODL[i];
				n3 = ISLE[i];
				n4 = NEGA[i];
				n5 = NUMB[i];
				n6 = POSI[i];
				k = i;
			} else if (MODL[i] == n2) {
				if (ISLE[i] < n3) {
					n3 = ISLE[i];
					n4 = NEGA[i];
					n5 = NUMB[i];
					n6 = POSI[i];
					k = i;
				} else if (ISLE[i] == n3) {
					if (NEGA[i] > n4) {
						n4 = NEGA[i];
						n5 = NUMB[i];
						n6 = POSI[i];
						k = i;
					} else if (NEGA[i] == n4) {
						if (NUMB[i] > n5) {
							n5 = NUMB[i];
							n6 = POSI[i];
							k = i;
						} else if (NUMB[i] == n5) {
							if (POSI[i] < n6) {
								n6 = POSI[i];
								k = i;
							}
						}
					}
				}
			}
		}
	}

#if (1 == GRP_PRINT)	
	printf ("k=%d as position variables\n", k);
#endif
	if (k != -1) {
		for (i=0; i<numVar; i++) {
			if (pop->CBO_posi[i] == POSI[k] && pop->CBO_nega[i] == NEGA[k] && 
			pop->M[i] == MODL[k] && pop->O[i] == ISLE[k]) {
				pop->I[i] = 0;
			} else {
				pop->I[i] = 1;
			}
		}
	} else {
		for (i=0; i<numVar; i++) {
			pop->I[i] = 1;
		}
	}
}

static void compute_M (Population_t* pop, Matrix_t* Y, int NP) {
	int		numVar = pop->var->colDim;
	int		numObj = pop->obj->colDim;
	double		L1[(NP+10)*numObj];
	double		L2[(NP+10)*numObj];
	int		i, j;

	// compute M 
	for (i=0; i<numVar; i++) {

		// get L1
		memcpy (L1, Y->elements+i*NP*numObj, NP*numObj*sizeof (double));
	
		// get L2
		for (j=0; j<NP; j++) {
			L2[j] = sum (L1+j*numObj, numObj);
		}
		
		if (L2[0] - L2[1] < 0) {
			for (j=1; j<NP-1; j++) 	if (L2[j] - L2[j+1] > DBL_EPSILON) break;
			if (j >= NP-1) { 
				pop->M[i] = 0;
			} else {
				pop->M[i] = 1;
			}
		} else { // L2[0] - L2[1] >= 0
			for (j=1; j<NP-1; j++) 	if (L2[j] - L2[j+1] < -DBL_EPSILON) break;
			for (j=j; j<NP-1; j++) 	if (L2[j] - L2[j+1] > DBL_EPSILON) break;
			if (j >= NP-1) { 
				pop->M[i] = 0;
			} else {
				pop->M[i] = 1;
			}
		}
	}
}

static void compute_O (Population_t* pop, Matrix_t* Y, int NP) {
	int		numVar = pop->var->colDim;
	int		numObj = pop->obj->colDim;
	double		L1[(NP+10)*numObj];
	double		O[numObj + 10];
	int		i, j, k;

	// compute O 
	for (i=0; i<numVar; i++) {

		// get L1
		memcpy (L1, Y->elements+i*NP*numObj, NP*numObj*sizeof (double));
		memcpy (L1+NP*numObj, pop->obj->elements, numObj*sizeof (double));
	
		// get O
		for (j=0; j<numObj; j++) {
			O[j] = L1[j];
		}
		for (k=1; k<=NP; k++) {
			for (j=0; j<numObj; j++) if (L1[k*numObj+j] < O[j]){
				O[j] = L1[k*numObj+j];
			}

		}
	
		// check O
		for (k=0, pop->O[i] = 0; k<=NP; k++) {
			for (j=0; j<numObj; j++) if (L1[k*numObj+j] > O[j]){
				break;
			}
			if (j >= numObj) {
				pop->O[i] = 1;
				break;
			}

		}
	}
}

static int  PYRCI_count;
static void print_Y_R_CBO_I (Population_t* pop, Matrix_t* Y, int NP) {
	int		numVar = pop->var->colDim;
	int		numObj = pop->obj->colDim;
	int		i, j, k;
	char		outputPattern[1024];
	int		run = Parameter_get()->run;
	long  		t  = time (NULL);
	int		No = PYRCI_count++;
	char*		fn = NULL;
	FILE*		fp = NULL;


	// 0.0 Pattern of output 
	sprintf (outputPattern, "output/%so%02dv%05d_%s_TYPE_%03d_%ld%04d", 
	(Problem_get())->title, numObj, numVar, (Parameter_get())->algorithm, run, t, No);


	// Y
	fn = strrep (outputPattern, (char *)"_TYPE_", (char *)"_Y_");
	fp = fopen (fn, "w");
	for (i=0; i<numVar; i++) {
		fprintf (fp, "var: %d\n", i);
		for (k=0; k<NP; k++) {
			for (j=0; j<numObj; j++) {
				fprintf (fp, "%.16f ", Y->elements[(i*NP+k)*numObj+j]);
			}
			fprintf (fp, "\n");
		}
	}
	fclose (fp);
	free (fn);

	// R
	fn = strrep (outputPattern, (char *)"_TYPE_", (char *)"_R_");
	fp = fopen (fn, "w");
	for (i=0; i<numVar; i++) {
		for (j=0; j<numVar; j++) {
			fprintf (fp, "(%d,%d) = %d\n", i, j, pop->R[i*numVar+j]);
		}
	}
	fclose (fp);
	free (fn);

	// I
	fn = strrep (outputPattern, (char *)"_TYPE_", (char *)"_I_");
	fp = fopen (fn, "w");
	for (i=0; i<numVar; i++) {
		fprintf (fp, "%d, (CBO, P, N, Z) = (%e, %d, %d, %d) | I = %d, M = %d\n", 
		i, pop->CBO[i], pop->CBO_posi[i], pop->CBO_nega[i], pop->CBO_zero[i], pop->I[i], pop->M[i]);
	}
	fclose (fp);
	free (fn);
}
 
static void perturb_analysis_variables_before_optimization (Population_t* pop) {
	int		numVar = pop->var->colDim;
	int		numObj = pop->obj->colDim;
	double*		lowBound = Problem_getLowerBound ();
	double*		uppBound = Problem_getUpperBound ();
	int		i, j, k, a;

	// 		paramter of perturbation	
	int 		NP = 10;		
	double		X[numVar+10]; 
	Matrix_t*	Y  = Matrix_new (numVar*NP, numObj); 
	double 		begin = randu () / (NP + 1); 
	double 		step;
	int		queue[numVar+10], len;
	int 		vis[numVar+10];

	// 0.1 alloc memory for R, CBO, M, I
	if (!pop->R) {
		pop->R = (int *)calloc(numVar*numVar, sizeof (int));
	}
	if (!pop->CBO) {
		pop->CBO = (double *)calloc(numVar, sizeof (double));
		pop->CBO_posi = (int *)calloc(numVar, sizeof (int));
		pop->CBO_nega = (int *)calloc(numVar, sizeof (int));
		pop->CBO_zero = (int *)calloc(numVar, sizeof (int));
	}
	if (!pop->M) {
		pop->M = (int *)calloc (numVar, sizeof (int));
	}
	if (!pop->I) {
		pop->I = (int *)calloc (numVar, sizeof (int));
	}
	if (!pop->O) {
		pop->O = (int *)calloc (numVar, sizeof (int));
	}

	// 0.2. set one point randomly:	Case one
	for (i=0; i<numVar; i++) {
		pop->var->elements[i] = lowBound[i] + begin*(uppBound[i] - lowBound[i]);
	}
	Problem_evaluate (pop->var->elements, numVar, pop->obj->elements, numObj);

	// 0.3 set I_flag into 0
	pop->I_flag = 0;

	// 1. perturb
	for (i=0; i<numVar; i++) {
		step = (uppBound[i] - lowBound[i]) / (NP + 1);
		for (j=0; j<NP; j++) {
			memcpy (X, pop->var->elements, numVar*sizeof (double));
			X[i] = pop->var->elements[i] + (j+1)*step;
			Problem_evaluate (X, numVar, Y->elements+i*NP*numObj+j*numObj, numObj);
		}
	}

	// 2. compute R 
	compute_R (pop, Y, NP);

	// 3. Group  Perturb
	memset (vis, 0, numVar*sizeof (int));
	for (i=0; i<numVar; i++) if (0 == vis[i]) {
		for (j=i, len=0; j<numVar; j++) {
			if (7 == pop->R[i*numVar+j]) {
				queue[len++] = j;
			}
		}
		if (1 == len) continue;
		for (j=0; j<NP; j++) {
			memcpy (X, pop->var->elements, numVar*sizeof (double));
			for (a=0; a<len; a++) {
				k = queue[a];
				step = (uppBound[k] - lowBound[k]) / (NP + 1);
				X[k] = pop->var->elements[k] + (j+1)*step;
			}
			Problem_evaluate (X, numVar, Y->elements+i*NP*numObj+j*numObj, numObj);
		}
		for (a=0; a<len; a++) {
			k = queue[a];
			if (k == i) continue;
			memcpy (Y->elements+k*NP*numObj, Y->elements+i*NP*numObj, NP*numObj*sizeof (double));
			vis[k] = 1;
		}
	}

	// 4. compute CBO 
	compute_CBO (pop, Y, NP);

	// 5. compuate M
	compute_M (pop, Y, NP);

	// 6. compuate O
	compute_O (pop, Y, NP);

	// 7. compuate I
	compute_I (pop, Y, NP);

	// 8. print print Y, R, CBO, I
	if (1 == GRP_PRINT) {
		print_Y_R_CBO_I (pop, Y, NP);
	}

	// free Y
	Matrix_free (&Y);
}

static void perturb_analysis_variables_after_optimization (Population_t* pop) {
	int		numVar = pop->var->colDim;
	int		numObj = pop->obj->colDim;
	double*		lowBound = Problem_getLowerBound ();
	double*		uppBound = Problem_getUpperBound ();
	int		i, j, k, a;

	// 		paramter of perturbation	
	int 		NP = 10;		
	double		X[numVar+10]; 
	Matrix_t*	Y  = Matrix_new (numVar*NP, numObj); 
	double 		begin = randu () / NP; 
	double 		step;
	int		queue[numVar+10], len;
	int 		vis[numVar+10];

	// 0.1 alloc memory for R, CBO, I
	if (!pop->R) {
		pop->R = (int *)calloc(numVar*numVar, sizeof (int));
	}
	if (!pop->CBO) {
		pop->CBO = (double *)calloc(numVar, sizeof (double));
		pop->CBO_posi = (int *)calloc(numVar, sizeof (int));
		pop->CBO_nega = (int *)calloc(numVar, sizeof (int));
		pop->CBO_zero = (int *)calloc(numVar, sizeof (int));
	}
	if (!pop->M) {
		pop->M = (int *)calloc (numVar, sizeof (int));
	}
	if (!pop->I) {
		pop->I = (int *)calloc (numVar, sizeof (int));
	}
	if (!pop->O) {
		pop->O = (int *)calloc (numVar, sizeof (int));
	}

	// 0.3 if pop->I_flag == 1
	if (pop->I_flag) {
		Matrix_free (&Y);
		return;
	}

	// 1. Group  Perturb
	memset (vis, 0, numVar*sizeof (int));
	for (i=0; i<numVar; i++) if (0 == vis[i]) {
		for (j=0, len=0; j<numVar; j++) {
			if (7 == pop->R[i*numVar+j]) {
				queue[len++] = j;
			}
		}
		for (j=0; j<NP; j++) {
			memcpy (X, pop->var->elements, numVar*sizeof (double));
			for (a=0; a<len; a++) {
				k = queue[a];
				step = (uppBound[k] - lowBound[k]) / NP;
				X[k] = lowBound[k] +  begin*(uppBound[k] - lowBound[k]) + j*step;
			}
			Problem_evaluate (X, numVar, Y->elements+i*NP*numObj+j*numObj, numObj);
		}
		for (a=0; a<len; a++) {
			k = queue[a];
			if (k == i) continue;
			memcpy (Y->elements+k*NP*numObj, Y->elements+i*NP*numObj, NP*numObj*sizeof (double));
			vis[k] = 1;
		}
	}


	// 2. compute CBO 
	compute_CBO (pop, Y, NP);

	// 3. compute M
	compute_M (pop, Y, NP);

	// 4. compuate O
	compute_O (pop, Y, NP);

	// 5. compute I
	compute_I (pop, Y, NP);

	// 6. print print Y, R, CBO, I
	if (1 == GRP_PRINT) {
		print_Y_R_CBO_I (pop, Y, NP);
	}

	// free Y
	Matrix_free (&Y);
}

/*************************************************************************************************************/
/*************	TPS  *****************************************************************************************/
/*************************************************************************************************************/

// TPS Optimize
static void TPS_optimize (Population_t* pop, double* bx, double* by, int* mask,  double (*g_func)(double *f, double *w, int M), double *gW) {
	int	numVar  = pop->var->colDim;
	int	numObj	= pop->obj->colDim; 
	double*	lowBound = Problem_getLowerBound ();
	double*	uppBound = Problem_getUpperBound ();

	// parameter of TPS
	double 	x[3*numVar], y[3*numObj]; 
	double	epsilon=1.0e-3, delta;
	int	i, j;
	double 	r1, r3;

	// allocate memory for biased flag
	if (pop->biased == NULL) {
		pop->biased = (int *)malloc ((numVar+10)*sizeof (int));
		for (i=0; i<numVar; i++) {
			pop->biased[i] = 1;
		}
	}

	// 1.2 Main loop  
	for (i=0; i<numVar; i++) if (1 == mask[i] && 1 == pop->biased[i]) {
		// set biased falg to 0
		pop->biased[i] = 0;

		// set delta
		delta = epsilon*(uppBound[i] - lowBound[i]);

		// 1.2.1 init the three points
		memcpy (x+0*numVar, bx, numVar*sizeof (double));
		memcpy (x+1*numVar, bx, numVar*sizeof (double));
		memcpy (x+2*numVar, bx, numVar*sizeof (double));
		memcpy (y+0*numObj, by, numObj*sizeof (double));
		memcpy (y+1*numObj, by, numObj*sizeof (double));
		memcpy (y+2*numObj, by, numObj*sizeof (double));

		// 1.2.2 perturb the three points 
		if (x[i] + delta > uppBound[i]) {
			x[0*numVar+i] = x[0*numVar+i] - 2*delta;
			x[1*numVar+i] = x[1*numVar+i] - 1*delta;
			Problem_evaluate (x+0*numVar, numVar, y+0*numObj, numObj);
			Problem_evaluate (x+1*numVar, numVar, y+1*numObj, numObj);
		} else if (x[i] - delta < lowBound[i]){
			x[1*numVar+i] = x[1*numVar+i] + 1*delta;
			x[2*numVar+i] = x[2*numVar+i] + 2*delta;
			Problem_evaluate (x+1*numVar, numVar, y+1*numObj, numObj);
			Problem_evaluate (x+2*numVar, numVar, y+2*numObj, numObj);
		} else {
			x[0*numVar+i] = x[0*numVar+i] - 1*delta;
			x[2*numVar+i] = x[2*numVar+i] + 1*delta;
			Problem_evaluate (x+0*numVar, numVar, y+0*numObj, numObj);
			Problem_evaluate (x+2*numVar, numVar, y+2*numObj, numObj);
		}
		
		// 1.2.3.1 tps
		tps (x, numVar, y, numObj, i, 1000, g_func, gW);

		// check if biased
		for (j=0; j<3; j++) {
			r1 = g_func (y+j*numObj, gW, numObj);
			r3 = g_func (by, gW, numObj);
			if (r1 < r3) {
				memcpy (bx, x+j*numVar, numVar*sizeof (double));
				memcpy (by, y+j*numObj, numObj*sizeof (double));

				if ((r3 - r1) > FLT_EPSILON) {
					pop->biased[i] = 1;
				}
			}
		}
	}
}

/*************************************************************************************************************/
/*************	Satisfy Conditions R  ************************************************************************/
/*************************************************************************************************************/

// 
static int SCR_index[1000000] = {-1};
static void satisfy_conditions_R (Population_t*pop, double *x) {
	double*	lowBound = Problem_getLowerBound ();
	double*	uppBound = Problem_getUpperBound ();
	int	numVar  = pop->var->colDim;
	int 	i, j;

	if (-1 == SCR_index[0]) for (i=numVar-1; i>=0; i--) {
		for (j=0; j<=i; j++) if (7 == pop->R[i*numVar+j]) {
			SCR_index[i] = j;
			break;
		}
	}

	for (i=0; i<numVar; i++) if (pop->I[i] && i != SCR_index[i]) {
		j = SCR_index[i];
		x[i] = ((x[j] - lowBound[j])/(uppBound[j] - lowBound[j]))*(uppBound[i] - lowBound[i]) + lowBound[i];
	}
}

/*************************************************************************************************************/
/*********************	Group Print  *************************************************************************/
/*************************************************************************************************************/

static void group_print (Population_t* pop) {		
	int	numVar  = pop->var->colDim;
	int	numObj  = pop->obj->colDim;
	int	run = Parameter_get()->run;
	long  	t  = time (NULL);
	char	fn[1024];
	FILE*	fp = NULL;
	char 	proname[64];		
	int	i, flag = 1;

	//  
	sprintf (fn, "output/%so%02dv%05d_%s_grp_%03d_%ld%04d", 
	(Problem_get())->title, numObj, numVar, (Parameter_get())->algorithm, run, t, 0);
	fp = fopen (fn, "w");

	strcpy (proname, Problem_get()->title);
	if (!strncmp (proname, (char *)"WFG", 3)) {
		for (i=0; i<2*(numObj-1); i++) if (0 != pop->I[i]) {
			flag = 0;
		#if (1 == GRP_PRINT)	
			printf ("Group of %s is wrong: pop->I[%d] = %d\n", proname, i, pop->I[i]);
		#endif
		}
		for (i=2*(numObj-1); i<numVar; i++) if (1 != pop->I[i]) {
			flag = 0;
		#if (1 == GRP_PRINT)	
			printf ("Group of %s is wrong: pop->I[%d] = %d\n", proname, i, pop->I[i]);
		#endif
		}
	} else if (!strncmp (proname, (char *)"LMF", 3)) {
		for (i=0; i<4; i++) if (0 != pop->I[i]) {
			flag = 0;
		#if (1 == GRP_PRINT)	
			printf ("Group of %s is wrong: pop->I[%d] = %d\n", proname, i, pop->I[i]);
		#endif
		}
		for (i=4; i<numVar; i++) if (1 != pop->I[i]) {
			flag = 0;
		#if (1 == GRP_PRINT)	
			printf ("Group of %s is wrong: pop->I[%d] = %d\n", proname, i, pop->I[i]);
		#endif
		}
	} else {
		for (i=0; i<numObj-1; i++) if (0 != pop->I[i]) {
			flag = 0;
		#if (1 == GRP_PRINT)	
			printf ("Group of %s is wrong: pop->I[%d] = %d\n", proname, i, pop->I[i]);
		#endif
		}
		for (i=numObj-1; i<numVar; i++) if (1 != pop->I[i]) {
			flag = 0;
		#if (1 == GRP_PRINT)	
			printf ("Group of %s is wrong: pop->I[%d] = %d\n", proname, i, pop->I[i]);
		#endif
		}
	}
	fprintf (fp, "%d\n", flag);
	fclose (fp);
}

/*************************************************************************************************************/
/*********************	The End  *****************************************************************************/
/*************************************************************************************************************/
