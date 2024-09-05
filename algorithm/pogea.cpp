#include "shape.h"
#include "population.h"
#include "algebra.h"
#include "recombination.h"
#include "terminal.h"
#include "myrandom.h"
#include "parameter.h"
#include "dominate.h"
#include "problem.h"
#include "crowding.h"
#include "rank.h"
#include "mystring.h"
#include "interactive.h"
#include "tps.h"
#include <string.h>
#include <float.h>

//
static void printObj (Matrix_t* Obj);

//
static void optimize_pop_by_smallproblem (Population_t *pop);
static void optimize_pop_by_sequence_individual (Population_t *pop);

//
static void optimize_pop_by_position_variables (Population_t *pop, int maxFitness);
static void optimize_pop_by_distance_variables (Population_t *pop, int maxFitness);

//
static int is_small_scale (Population_t* pop);		// check if it is small-scale problem

// Main frame of POGEA
Population_t* pogea (Problem_t *problem) {
	Population_t* 	pop = NULL;

	// 1. new a population
	pop = Population_new (problem, (Parameter_get())->popSize);
	isTerminal (pop);

	// 2. variable difference: 
	Population_difference (pop);

	// 3. check if it is a small scale problem
	if (is_small_scale (pop)) {
		printf ("optimize small scale problem\n");
		optimize_pop_by_smallproblem (pop); 		// optimize small-scale problem: ZDT1-4,5 ZDTL1-7, WFG2-7
	} else {
		printf ("optimize large scale problem\n");
		optimize_pop_by_sequence_individual (pop);
	}

	return pop;
}

static int is_small_scale (Population_t* pop) {	
	int 	K = 100;

	if (pop->basicV->nNode < K) {
		return 1;
	}
	return 0;
}

static int isFlat (Population_t* pop) {
	int		popSize= pop->var->rowDim;
	int		numObj = pop->obj->colDim;
	Matrix_t*	M = Matrix_new (popSize, 1);
	int*		index = NULL;
	int		i, j, flat = 0;

	for (i=0; i<popSize; i++) {
		for (j=0; j<numObj; j++) {
			M->elements[i] += pop->obj->elements[i*numObj+j];
		}
	}
	index = sort (M);
	if (M->elements[index[popSize-2]] - M->elements[index[1]] < FLT_EPSILON) {
		flat = 1;
	}
	free (index);
	Matrix_free (&M);

	return flat;
}


// fake tps
static void tps (double *x, int numVar, double *y, int numObj, int i, int FEs) {

}

static void tps_for_small (Population_t* pop) {
	Matrix_t* 	Var 	= pop->var; 
	Matrix_t* 	Obj 	= pop->obj;
	int		popSize = Var->rowDim;
	int		numVar  = Var->colDim;
	int		numObj	= Obj->colDim;
	double*		lowBound = Problem_getLowerBound ();
	double*		uppBound = Problem_getUpperBound ();
	int 		i, j, k;
	double 		x[3*numVar], y[3*numObj]; 
	double		h0, h1, h2;
	double 		p[numVar];
	double		epsilon=1.0e-3;
	long long 	fitness = Problem_getFitness ();
	char		outputPattern[1024];
	char*		fn = NULL;
	FILE*		fp = NULL;
	int*		array = Link2Array (pop->basicV);

	// Pattern of output 
	sprintf (outputPattern, "output/%so%02dv%05d_%s_TYPE_%03d_%ld%04d", 
		(Problem_get())->title, numObj, numVar, (Parameter_get()->algorithm), Parameter_get()->run, time(NULL), 1);

	//
	for (k=array[0]; k>0; k--) {
		i = array[k];
		if (pop->I[i]) {
			// init x, y
			for (j=0; j<3; j++) {
				memcpy (x+j*numVar, pop->var->elements, numVar*sizeof (double));
			}
			x[0*numVar+i] = x[1*numVar+i] - epsilon*(uppBound[i] - lowBound[i]);
			x[2*numVar+i] = x[1*numVar+i] + epsilon*(uppBound[i] - lowBound[i]);
			if (x[0*numVar+i] < lowBound[i]) {
				x[0*numVar+i] = lowBound[i];
				x[2*numVar+i] = 2*x[1*numVar+i] - x[0*numVar+i];
			}
			if (x[2*numVar+i] > uppBound[i]) {
				x[2*numVar+i] = uppBound[i];
				x[0*numVar+i] = 2*x[1*numVar+i] - x[2*numVar+i];
			}
			for (j=0; j<3; j++) {
				Problem_evaluate (x+j*numVar, numVar, y+j*numObj, numObj);
			}
			
			// fake tps 
			tps (x, numVar, y, numObj, i, 1000);
			h0 = sum (y+0*numObj, numObj);
			h1 = sum (y+1*numObj, numObj);
			h2 = sum (y+2*numObj, numObj);
			if ((h0 - h1) <= 0 && (h0 - h2) <= 0) {
				p[i] = x[0*numVar+i];
			} else if ((h1 - h0) <=0 && (h1 - h2) <= 0) {
				p[i] = x[1*numVar+i];
			} else {
				p[i] = x[2*numVar+i];
			}
		}
	}

	// resive dicision variable 
	Population_exec_difference (pop, p);
	
	//
	for (i=0; i<popSize; i++) {
		memcpy (x, p, numVar*sizeof (double));
		for (j=0; j<numVar; j++) if (!pop->I[j]) {
			x[j] = Var->elements[i*numVar+j];
		}
		Problem_evaluate (x, numVar, y, numObj);
		if (isDominate (y, Obj->elements+i*numObj, numObj) == 1) {
			memcpy (Var->elements+i*numVar, x, numVar*sizeof (double));
			memcpy (Obj->elements+i*numObj, y, numObj*sizeof (double));
		}
	}

	// printf bs 
	fn = strrep (outputPattern, (char *)"_TYPE_", (char *)"_bs_");
	fp = fopen (fn, "w");
	fitness = Problem_getFitness() - fitness;
	fprintf (fp, "%.2e\n", 1.0*fitness/Problem_get()->lifetime);
	fclose (fp);
	free (fn);
}


static void optimize_pop_by_smallproblem (Population_t *pop) {
	Optimize_t*	opt = (Optimize_t *)calloc (1, sizeof (Optimize_t));

	// set parameter for optimization
	opt->reproduce = SBX;
	opt->var = pop->basicV;
        opt->select = Tournament;
	opt->repeller = NULL;               
	opt->isExec_difference = 1;      
	opt->rank = Hypervolume;

	// optimize
	while (!isTerminal (pop) && (Problem_get()->fitness < Problem_get()->lifetime/2)) {
		Population_optimize_next (pop, opt);	
	}

	// three points search
 	tps_for_small (pop);

	if ( !isFlat (pop)) {
		opt->rank = Crowding;
	}

	// optimize
	while (!isTerminal (pop)) {
		Population_optimize_next (pop, opt);	
	}
	
	// free
	free (opt);
}

static void next_position_variables (Population_t *pop, int p) {
	int		numVar  = pop->var->colDim;
	int		numObj  = pop->obj->colDim;
	double*		lowBound = Problem_getLowerBound ();
	double*		uppBound = Problem_getUpperBound ();
	int		i, j, k; 
	Matrix_t*	M = NULL;
	int*		index = NULL;
	Matrix_t*	Var = NULL;
	int 		queue[numVar+10], n=0;
	double		t, d;

	// position variables
	for (i=0; i<numVar; i++) if (!pop->I[i]){
		queue[n++] = i;
	}

	// p = 0
	if (0 == p) {
		for (i=0; i<n; i++) {
			j = queue[i];
			pop->var->elements[p*numVar+j] = lowBound[j];
		}
		return;
	}

	// p = 1
	if (1 == p) {
		for (i=0; i<n; i++) {
			j = queue[i];
			pop->var->elements[p*numVar+j] = uppBound[j];
		}
		return;
	}

	// p > 2
	k = rand() % numObj;	// 
	M = Matrix_new (p, 2); 	// [ obj_k, index]
	for (i=0; i<p; i++) {
		M->elements[i*2+0] = pop->obj->elements[i*numObj+k];
		M->elements[i*2+1] = i + 0.1;
	}
	index = sort (M);	
	
	for (i=0, d=-1; i<p-1; i++) {
		t = M->elements[index[i+1]*2+0] - M->elements[index[i]*2+0];
		if (t > d) {
			d = t;
			k = i;
		}
	}

	for (i=0; i<n; i++) {
		j = queue[i];
		Var = pop->var;
		Var->elements[p*numVar+j] = 0.5*(Var->elements[index[k]*numVar+j] + Var->elements[index[k+1]*numVar+j]);
	}

	free (index);
	Matrix_free (&M);
}

static int  num_check;
static void check_pop_state (Population_t *pop, Matrix_t *repeller) {
	int 		i, j, k;
	int		popSize= pop->var->rowDim;
	int		numVar = pop->var->colDim;
	int		numObj = pop->obj->colDim;
	double*		lowBound = Problem_getLowerBound ();
	double*		uppBound = Problem_getUpperBound ();
	int		changed = 0;
	double		d;

	if (repeller == NULL)
		return;
	
	for (i=0; i<popSize; i++) {
		changed = 0;
		for (j=0; j<numVar; j++) if (pop->I[j]) {	
			d = (uppBound[j] - lowBound[j])*1.0e-3;
			for (k=0; k<repeller->rowDim; k++) { 
				if (fabs(pop->var->elements[i*numVar+j] - repeller->elements[k*numVar+j]) < d) {
					pop->var->elements[i*numVar+j] = lowBound[j] + randu()*(uppBound[j]-lowBound[j]);
					changed = 1;
					break;
				}
			}
		}
		if (changed) {
			Problem_evaluate (pop->var->elements+i*numVar, numVar, pop->obj->elements+i*numObj, numObj);
			num_check++;
		}
	}
}

static void update_pop_by_repeller (Population_t *pop, Matrix_t* repeller) {
	int 		i, j;
	int		numVar = pop->var->colDim;
	int		numObj = pop->obj->colDim;
	double		x[numVar+10], y[numObj+10];
		
	for (i=0; i<repeller->rowDim; i++) {
		for (j=0; j<numVar; j++) if (pop->I[j] && pop->C[j] <= numObj) {
			memcpy (x, pop->var->elements, numVar*sizeof (double));
			x[j] = repeller->elements[i*numVar+j];
			
			// evaluate
			Problem_evaluate (x, numVar, y, numObj);

			//
			if (isDominate (y, pop->obj->elements, numObj) == 1) {
				memcpy (pop->var->elements, x, numVar*sizeof (double));
				memcpy (pop->obj->elements, y, numObj*sizeof (double));
			}
		}
	}

	printf ("optimum: | after update\n");
	for (j=0; j<numVar; j++) {
		printf ("%4d", j);	
		for (i=0; i<repeller->rowDim; i++) {
			printf (" %.16e", repeller->elements[i*numVar+j]);
		}
		printf (" | %.16e\n", pop->var->elements[j]);
	}

	printf ("%.16e, %.16e\n", pop->obj->elements[0], pop->obj->elements[1]);
}

static int isLinkage (Population_t* pop) {
	int		numVar  = pop->var->colDim;
	int		i, j;
	int		NIA = 5;

	for (i=0; i<numVar; i++) if (!pop->I[i]) {
		for (j=0; j<numVar; j++) if (pop->I[j]) {
			if (isInteractive(i, j, NIA)) {
				return 1;
			}
		}
	}
	return 0;
}

static void optimize_pop_by_position_variables (Population_t *pop, int maxFitness) {
	int		numVar  = pop->var->colDim;
	int 		i, k;
	Link_t*		link = NULL;
	Optimize_t*	opt = (Optimize_t *)calloc (1, sizeof (Optimize_t));
	int		FEs = maxFitness / 2;

	// get position variables
	for (i=0; i<numVar; i++) if (!pop->I[i]) {
		Link_add (&link, i);
	}

	// set optimization parameters
	opt->reproduce = SBX;
	opt->var = link;
        opt->select = Random;
	opt->repeller = NULL;               
	opt->isExec_difference = 0;      
	opt->rank = Hypervolume;
	
	// print Obj
	printObj (pop->obj);

	// optimize
	for (k=0; k<FEs; k++ ) {
		if ((k&1) == 1) {
			opt->reproduce = SBX;
		} else {
			opt->reproduce = Half;
		}
		Population_optimize_next (pop, opt);	
		isTerminal (pop);

		// print Obj
		if (k % 1000 == 999) {
			printObj (pop->obj);
		}
	}

	// check if shape of PF is flat
	if (!isFlat (pop)) {
		opt->rank = Crowding;
	}

	// optimize
	for (k=0; k<FEs; k++) {
		if ((k&1) == 1) {
			opt->reproduce = SBX;
		} else {
			opt->reproduce = Half;
		}
		Population_optimize_next (pop, opt);	
		isTerminal (pop);

		// print Obj
		if (k % 1000 == 999) {
			printObj (pop->obj);
		}
	}
	
	// optimimze
	while (!isTerminal(pop)) {
		if ((k&1) == 1) {
			opt->reproduce = SBX;
			k++;
		} else {
			opt->reproduce = Half;
			k++;
		}
		Population_optimize_next (pop, opt);	

		// print Obj
		if (k % 1000 == 999) {
			printObj (pop->obj);
		}
	}
	
	// free
	Link_free (&link);
	free (opt);
}

static void optimize_pop_by_distance_variables (Population_t *pop, int maxFitness) {
	int		popSize = pop->var->rowDim;
	int		numVar  = pop->var->colDim;
	int		numObj  = pop->obj->colDim;
	double*		lowBound = Problem_getLowerBound ();
	double*		uppBound = Problem_getUpperBound ();
	int 		i, k, n;
	Link_t*		link = NULL;
	Optimize_t*	opt = (Optimize_t *)calloc (1, sizeof (Optimize_t));
	int		NR  = 3;
	double 		x[3*numVar], y[3*numObj]; 
	double 		h0, h1, h2;
	double		epsilon = 1.0e-3;
	int		FEs = maxFitness/4;
	
	// get distance variables
	for (i=0; i<numVar; i++) if (pop->I[i] && pop->C[i] <=numObj) {
		Link_add (&link, i);
	}

	// set optimization parameters
	opt->reproduce = SBX;
	opt->var = link;
        opt->select = Tournament;
	opt->repeller = Matrix_new (NR, numVar);               
	opt->repeller->rowDim = 0;
	opt->isExec_difference = 0;      
	opt->rank = Sum;

	// get repellers
	for (n=0; n<NR; n++) {
		// optimize
		for (k=0; k<FEs; k++) {
			if (k%100 == 99) {
				check_pop_state (pop, opt->repeller);
			}
			Population_optimize_next (pop, opt);
		}

		// record repeller
		memcpy (opt->repeller->elements+n*numVar, pop->var->elements, numVar*sizeof (double));
		opt->repeller->rowDim = n+1;
		
		// tps
		for (i=0; i<numVar; i++) if (pop->I[i] && pop->C[i] <= numObj) {
			//
			memcpy (x+0*numVar, pop->var->elements, numVar*sizeof (double));
			memcpy (x+1*numVar, pop->var->elements, numVar*sizeof (double));
			memcpy (x+2*numVar, pop->var->elements, numVar*sizeof (double));
			x[0*numVar+i] = x[1*numVar+i] - epsilon*(uppBound[i] - lowBound[i]);
			x[2*numVar+i] = x[1*numVar+i] + epsilon*(uppBound[i] - lowBound[i]);
			if (x[0*numVar+i] < lowBound[i]) {
				x[0*numVar+i] = lowBound[i];
				x[2*numVar+i] = 2*x[1*numVar+i] - x[0*numVar+i];
			}
			if (x[2*numVar+i] > uppBound[i]) {
				x[2*numVar+i] = uppBound[i];
				x[0*numVar+i] = 2*x[1*numVar+i] - x[2*numVar+i];
			}
			memcpy (y+1*numObj, pop->obj->elements, numObj*sizeof (double));
			Problem_evaluate (x+0*numVar, numVar, y+0*numObj, numObj);
			Problem_evaluate (x+2*numVar, numVar, y+2*numObj, numObj);

			// fake tps
			tps (x, numVar, y, numObj, i, 1000);

			//
			h0 = sum (y+0*numObj, numObj);
			h1 = sum (y+1*numObj, numObj);
			h2 = sum (y+2*numObj, numObj);
			if ((h0 - h1) <= 0 && (h0 - h2) <= 0) {
				opt->repeller->elements[n*numVar+i] = x[0*numVar+i];
			} else if ((h1 - h0) <=0 && (h1 - h2) <= 0) {
				opt->repeller->elements[n*numVar+i] = x[1*numVar+i];
			} else {
				opt->repeller->elements[n*numVar+i] = x[2*numVar+i];
			}
		}
	}

	// update pop with repeller
	update_pop_by_repeller (pop, opt->repeller);
	
	// append repeller into pop
	for (n=0; n<opt->repeller->rowDim; n++)	{
		memcpy (pop->var->elements+(popSize-1-n)*numVar, opt->repeller->elements+n*numVar, numVar*sizeof(double));
		Problem_evaluate (pop->var->elements+(popSize-1-n)*numVar, numVar, 
				  pop->obj->elements+(popSize-1-n)*numObj, numObj);
	}
	Matrix_free (&opt->repeller);

	// optimize
	for (k=0; k<FEs; k++) {
		Population_optimize_next (pop, opt);
	}

	// free
	Link_free (&link);
	free (opt);
}

static void optimize_pop_by_sequence_individual_linkage_yes (Population_t *pop) {
	int		popSize = pop->var->rowDim;
	int		numVar  = pop->var->colDim;
	int		numObj  = pop->obj->colDim;
	double*		lowBound = Problem_getLowerBound ();
	double*		uppBound = Problem_getUpperBound ();
	int 		i, j, ind;
	int		innerPopsize = popSize;
	Population_t*	innerPop = (Population_t *)calloc (1, sizeof (Population_t));
	int		maxFitness;

	// set terminal condition 
	maxFitness = (Problem_get()->lifetime - Problem_get()->fitness)/popSize;
	
	// set inner population size
	innerPop->var = Matrix_new (2*innerPopsize, numVar);
	innerPop->obj = Matrix_new (2*innerPopsize, numObj);
	innerPop->var->rowDim = innerPopsize;
	innerPop->obj->rowDim = innerPopsize;
	innerPop->I   = pop->I;
	innerPop->C   = pop->C;

	// print Obj
	printObj (pop->obj);

	// optimize
	for (ind=0; ind<popSize; ind++) {
		printf ("%d/%d\n", ind, popSize);

		// get position variables
		next_position_variables (pop, ind);

		// init inner pop
		for (i=0; i<innerPopsize; i++) {
			for (j=0; j<numVar; j++) if (!pop->I[j]){
				innerPop->var->elements[i*numVar+j] = pop->var->elements[ind*numVar+j];
			} else {
				innerPop->var->elements[i*numVar+j] = lowBound[j] + randu()*(uppBound[j]-lowBound[j]);
			}
			Problem_evaluate (innerPop->var->elements+i*numVar,numVar,innerPop->obj->elements+i*numObj,numObj);
		}
	
		// optimize distance variables of inner pop
		optimize_pop_by_distance_variables (innerPop, maxFitness);

		// get an individual  
		memcpy (pop->var->elements+ind*numVar, innerPop->var->elements, numVar*sizeof (double));	
		memcpy (pop->obj->elements+ind*numObj, innerPop->obj->elements, numObj*sizeof (double));	

		// check if terminal
		isTerminal (pop);

		// print Obj
		printObj (pop->obj);
	}

	Matrix_free (&innerPop->obj);
	Matrix_free (&innerPop->var);
	free (innerPop);
}

static void optimize_pop_by_sequence_individual_linkage_no (Population_t *pop) {
	int		popSize = pop->var->rowDim;
	int		numVar  = pop->var->colDim;
	int		numObj  = pop->obj->colDim;
	double*		lowBound = Problem_getLowerBound ();
	double*		uppBound = Problem_getUpperBound ();
	int 		i, j;
	int		maxFitness;

	// set terminal condition 
	maxFitness = (Problem_get()->lifetime - Problem_get()->fitness)/popSize;

	// uniform position variables
	for (i=1; i<popSize; i++) {
		for (j=0; j<numVar; j++) if (!pop->I[j]) {
			pop->var->elements[i*numVar+j] = pop->var->elements[0*numVar+j];
		}
		Problem_evaluate (pop->var->elements+i*numVar, numVar, pop->obj->elements+i*numObj, numObj);	
	}

	// optimize distance variables
	optimize_pop_by_distance_variables (pop, 3*maxFitness/4);

	// uniform distance variables and random initialize position variables
	for (i=1; i<popSize; i++) {
		for (j=0; j<numVar; j++) if (pop->I[j]) {
			pop->var->elements[i*numVar+j] = pop->var->elements[0*numVar+j];
		}else {
			pop->var->elements[i*numVar+j] = lowBound[j] + randu()*(uppBound[j]-lowBound[j]);
		}
		Problem_evaluate (pop->var->elements+i*numVar, numVar, pop->obj->elements+i*numObj, numObj);	
	}

	// optimze position variables
	optimize_pop_by_position_variables (pop, maxFitness/4);
}

static void optimize_pop_by_sequence_individual (Population_t *pop) {
	if (isLinkage (pop)) {
		printf ("optimize by sequence of individual: large-scale, linkage: Yes\n");
		optimize_pop_by_sequence_individual_linkage_yes (pop);
	} else {
		printf ("optimize by sequence of individual: large-scale, linkage: No\n");
		optimize_pop_by_sequence_individual_linkage_no (pop);
	}
}

//
static int  num_printObj;
static void printObj (Matrix_t* Obj) {
	char	fn[1024];

	num_printObj++;
	sprintf (fn, "./tmp/A%08d", num_printObj);
	Matrix_print (Obj, (char *)fn);
}
