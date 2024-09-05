#include "tps.h"
#include "problem.h"
#include "algebra.h"
#include "population.h"
#include "myrandom.h"
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <float.h>

#define PRINT 0

//
static int 	FE;
static int 	maxFE;
static double 	(*g_func)(double *f, double *w, int M); 
static double 	*gW;

// 
static void print_data (double *x, int numVar, double *y, int numObj, int i, char *extra) {
	double 	h0, h1, h2;
	//
	h0 = g_func (y+0*numObj, gW, numObj);
	h1 = g_func (y+1*numObj, gW, numObj);
	h2 = g_func (y+2*numObj, gW, numObj);
	//
	printf ("%s: %d, %d, (%.16f %.2e %2e), %.16e, %.16e\n",
	extra, i , FE , x[1*numVar+i], x[1*numVar+i]-x[0*numVar+i], x[2*numVar+i]-x[1*numVar+i], h0-h1, h1-h2);
}

// 
static void shift_right_big (double *x, int numVar, double *y, int numObj, int i) {
	double 	t;

	// new value
	t = 2*x[2*numVar+i] - x[0*numVar+i]; 
	//
	if (t != x[2*numVar+i]) {
		// 1.1 x_1 jump to x_2
		x[1*numVar+i] =  x[2*numVar+i];
		memcpy (y+1*numObj, y+2*numObj, numObj*sizeof (double));

		// 1.2 x_2 jump to 2 * x_1 - x_0
		x[2*numVar+i] = 2 * x[1*numVar+i] - x[0*numVar+i];
		Problem_evaluate (x+2*numVar, numVar, y+2*numObj, numObj);
		FE++;
	} else {
		// 2.1 x_0 jump to x_2
		x[0*numVar+i] =  x[2*numVar+i];
		memcpy (y+0*numObj, y+2*numObj, numObj*sizeof (double));

		// 2.2 x_1 jump to x_2
		x[1*numVar+i] =  x[2*numVar+i];
		memcpy (y+1*numObj, y+2*numObj, numObj*sizeof (double));
	}

	// print
	if (PRINT) print_data (x, numVar, y, numObj, i, (char *)"R");
}

static void shift_right_small (double *x, int numVar, double *y, int numObj, int i) {
	double*	uppBound = Problem_getUpperBound ();
	double	t;

	// the new value
	t = 0.5 * (x[1*numVar+i] + x[2*numVar+i]);
	//
	if (t != x[1*numVar+i] && t != x[2*numVar+i]) {
		// 1.1 x_0 jump to x_1
		x[0*numVar+i] =  x[1*numVar+i];
		memcpy (y+0*numObj, y+1*numObj, numObj*sizeof (double));

		// 1.2 x_1 jump to (x_0 + x_2)/2
		x[1*numVar+i] = 0.5 * (x[0*numVar+i] + x[2*numVar+i]);
		Problem_evaluate (x+1*numVar, numVar, y+1*numObj, numObj);
		FE++;
	} else {
		if (2*x[2*numVar+i]-x[0*numVar+i] <= uppBound[i]) {
			shift_right_big (x, numVar, y, numObj, i);
		} else if (x[2*numVar+i] != uppBound[i]) {
			// 2.1 x_1 jump to x_2
			x[1*numVar+i] = x[2*numVar+i];
			memcpy (y+1*numObj, y+2*numObj, numObj*sizeof (double));
			
			// 2.2 x_2 jump to uppBound[i]
			x[2*numVar+i] = uppBound[i];
			Problem_evaluate (x+2*numVar, numVar, y+2*numObj, numObj);
			FE++;
		} else {
			// 2.3 x_0 jump to x_1
			x[0*numVar+i] = x[1*numVar+i];
			memcpy (y+0*numObj, y+1*numObj, numObj*sizeof (double));
		}
	}

	// print
	if (PRINT) print_data (x, numVar, y, numObj, i, (char *)"r");
}

static void shift_left_big (double *x, int numVar, double *y, int numObj, int i) {
	double t;

	// new value
	t = 2*x[0*numVar+i] - x[2*numVar+i];
	//
	if (t != x[0*numVar+i]) {
		// 1.1 x_1 jump to x_0
		x[1*numVar+i] =  x[0*numVar+i];
		memcpy (y+1*numObj, y+0*numObj, numObj*sizeof (double));

		// 1.2 x_0 jump to 2 * x_1 - x_2
		x[0*numVar+i] = 2 * x[1*numVar+i] - x[2*numVar+i];
		Problem_evaluate (x+0*numVar, numVar, y+0*numObj, numObj);
		FE++;
	} else {
		// 2.1 x_1 jump to x_0
		x[1*numVar+i] =  x[0*numVar+i];
		memcpy (y+1*numObj, y+0*numObj, numObj*sizeof (double));

		// 2.2 x_2 jump to x_0
		x[2*numVar+i] =  x[0*numVar+i];
		memcpy (y+2*numObj, y+0*numObj, numObj*sizeof (double));
	}

	// print
	if (PRINT) print_data (x, numVar, y, numObj, i, (char *)"L");
}


static void shift_left_small (double *x, int numVar, double *y, int numObj, int i) {
	double*	lowBound = Problem_getLowerBound ();
	double	t;
	
	// new value
	t = 0.5 * (x[0*numVar+i] + x[1*numVar+i]);
	//
	if (t != x[0*numVar+i] && t != x[1*numVar+i]) {
		// 1.1 x_2 jump to x_1
		x[2*numVar+i] =  x[1*numVar+i];
		memcpy (y+2*numObj, y+1*numObj, numObj*sizeof (double));

		// 1.2 x_1 jump to (x_0 + x_2)/2
		x[1*numVar+i] = 0.5 * (x[0*numVar+i] + x[2*numVar+i]);
		Problem_evaluate (x+1*numVar, numVar, y+1*numObj, numObj);
		FE++;
	} else {
		if (2*x[0*numVar+i]-x[2*numVar+i] >= lowBound[i]) {
			shift_left_big (x, numVar, y, numObj, i);
		} else if (x[0*numVar+i] != lowBound[i]){
			// 2.1 x_1 jump to x_0
			x[1*numVar+i] = x[0*numVar+i];
			memcpy (y+1*numObj, y+0*numObj, numObj*sizeof (double));

			// 2.2 x_0 jump to lowBound[i]
			x[0*numVar+i] = lowBound[i];
			Problem_evaluate (x+0*numVar, numVar, y+0*numObj, numObj);
			FE++;
		} else {
			// 2.3 x_2 jump to x_1
			x[2*numVar+i] = x[1*numVar+i];
			memcpy (y+2*numObj, y+1*numObj, numObj*sizeof (double));
		}
	}

	// print
	if (PRINT) print_data (x, numVar, y, numObj, i, (char *)"l");
}

static void shift_middle_small (double *x, int numVar, double *y, int numObj, int i) {
	double 	t;

	// new value
	t = 0.5 * (x[0*numVar+i] + x[1*numVar+i]);
	if (t != x[0*numVar+i]) {
		// 1.1 x_0 jump to (x_0 + x_1)/2
		x[0*numVar+i] = 0.5 * (x[0*numVar+i] + x[1*numVar+i]);
		Problem_evaluate (x+0*numVar, numVar, y+0*numObj, numObj);
		FE++;
	} else {
		// 1.2 x_0 jump to x_1
		x[0*numVar+i] = x[1*numVar+i];
		memcpy (y+0*numObj, y+1*numObj, numObj*sizeof (double));
	}
	
	// new value
	t = 0.5 * (x[1*numVar+i] + x[2*numVar+i]);
	if (t != x[2*numVar+i]) {
		// 2.1 x_2 jump to (x_1 + x_2)/2
		x[2*numVar+i] =  0.5*(x[1*numVar+i] + x[2*numVar+i]);
		Problem_evaluate (x+2*numVar, numVar, y+2*numObj, numObj);
		FE++;
	} else {
		// 2.2 x_2 jump to x_1
		x[2*numVar+i] = x[1*numVar+i];
		memcpy (y+2*numObj, y+1*numObj, numObj*sizeof (double));
	}

	// print
	if (PRINT) print_data (x, numVar, y, numObj, i, (char *)"m");
}

static int is_optimum (double *x, int numVar, double *y, int numObj, int i) {
	double*	lowBound = Problem_getLowerBound ();
	double*	uppBound = Problem_getUpperBound ();
	double	X[numVar];
	double	Y[numObj];
	double 	h1, h2;
	int	k, NP = 10;

	if (x[2*numVar+i] != uppBound[i]) for (k=0; k<NP; k++) {
		memcpy (X, x+2*numVar, numVar*sizeof (double));
		X[i] = X[i] + (k + randu()) * (uppBound[i] - X[i]) / NP;
		Problem_evaluate (X, numVar, Y, numObj);
		FE++;

		h1 = g_func (y+2*numObj, gW, numObj);
		h2 = g_func (Y, gW, numObj);
		if (h2 < h1) {
			// x_2 jump to X
			memcpy (x+2*numVar, X, numVar*sizeof (double));
			memcpy (y+2*numObj, Y, numObj*sizeof (double));

			// x_0 jump to x1
			memcpy (x+0*numVar, x+1*numVar, numVar*sizeof (double));
			memcpy (y+0*numObj, y+1*numObj, numObj*sizeof (double));

			// x1 jump to (x_0 + x_2)/2
			x[1*numVar+i] = 0.5 * (x[0*numVar+i] + x[2*numVar+i]);
			Problem_evaluate (x+1*numVar, numVar, y+1*numObj, numObj);
			FE++;

			// print
			if (PRINT) print_data (x, numVar, y, numObj, i, (char *)"is_Optimum");

			return 0;
		}
	}

	if (x[0*numVar+i] != lowBound[i]) for (k=0; k<NP; k++) {
		memcpy (X, x+0*numVar, numVar*sizeof (double));
		X[i] = X[i] - (k + randu ())*(X[i] - lowBound[i]) / NP;
		Problem_evaluate (X, numVar, Y, numObj);
		FE++;

		h1 = g_func (y+0*numObj, gW, numObj);
		h2 = g_func (Y, gW, numObj);
		if (h2 < h1) {
			// x_0 jump to X
			memcpy (x+0*numVar, X, numVar*sizeof (double));
			memcpy (y+0*numObj, Y, numObj*sizeof (double));

			// x_2 jump to x1
			memcpy (x+2*numVar, x+1*numVar, numVar*sizeof (double));
			memcpy (y+2*numObj, y+1*numObj, numObj*sizeof (double));

			// x1 jump to (x_0 + x_2)/2
			x[1*numVar+i] = 0.5 * (x[0*numVar+i] + x[2*numVar+i]);
			Problem_evaluate (x+1*numVar, numVar, y+1*numObj, numObj);
			FE++;

			// print
			if (PRINT) print_data (x, numVar, y, numObj, i, (char *)"isOptimum");

			return 0;
		}
	}

	return 1;
}

// x0, x1, x2 meet (x0 < x1 < x2) and (x0 + x2 == 2 * x1)
static void tps(double *x, int numVar, double *y, int numObj, int i, int maxFE_input) {
	double 	h0, h1, h2; 
	double*	lowBound = Problem_getLowerBound ();
	double*	uppBound = Problem_getUpperBound ();
	
	// set FE and maxFE
	FE 	= 0;
	maxFE 	= maxFE_input;
	
	// update x, y, h
	while (FE < maxFE) {
		// aggregate 
		h0 = g_func (y+0*numObj, gW, numObj);
		h1 = g_func (y+1*numObj, gW, numObj);
		h2 = g_func (y+2*numObj, gW, numObj);

		// shift 
		if ((h0 - h1) < 0 && (h1 - h2) < 0) {
			if ((2.0*x[0*numVar+i] - x[2*numVar+i]) >= lowBound[i]) {
				shift_left_big (x, numVar, y, numObj, i);		// shift_left_big
			} else {
				shift_left_small (x, numVar, y, numObj, i);		// shift_left_small
			} 
		} else if ((h0 - h1) < 0 && (h1 - h2) == 0) {
			shift_left_small (x, numVar, y, numObj, i);			// shift_left_small
		} else if ((h0 - h1) < 0 && (h1 - h2) > 0) {
			if ((h0 - h2) < 0) {
				shift_left_small (x, numVar, y, numObj, i);		// shift_left_small
			} else {
				shift_right_small (x, numVar, y, numObj, i);		// shift_right_small
			}
		} else if ((h0 - h1) == 0 && (h1 - h2) < 0) {
			shift_left_small (x, numVar, y, numObj, i);			// shift_left_small
		} else if ((h0 - h1) == 0 && (h1 - h2) == 0) {
			break;
			if (1 == is_optimum (x, numVar, y, numObj, i)) { 
				break;
			}
		} else if ((h0 - h1) == 0 && (h1 - h2) > 0) {
			shift_right_small (x, numVar, y, numObj, i);			// shift_right_small
		} else if ((h0 - h1) > 0 && (h1 - h2) < 0) {
			shift_middle_small (x, numVar, y, numObj, i);			// shift_middle_small
		} else if ((h0 - h1) > 0 && (h1 - h2) == 0) {
			shift_right_small (x, numVar, y, numObj, i);			// shift_right_small
		} else if ((h0 - h1) > 0 && (h1 - h2) > 0){
			if ((2.0*x[2*numVar+i] - x[0*numVar+i]) <= uppBound[i]) {
				shift_right_big (x, numVar, y, numObj, i);		// shift_right_big
			} else {
				shift_right_small (x, numVar, y, numObj, i);		// shift_right_small
			}
		}
	}
}

void tps(double *x, int numVar, double *y, int numObj, int i, int maxFitness, double (*g_func_input)(double *f, double *w, int M), double *gW_input) 
{
	// init 
	g_func 	= g_func_input;
	gW 	= gW_input;

	//
	tps (x, numVar, y, numObj, i, maxFitness);
}

//
void tps_init (double *x, int numVar, double *y, int numObj, int i, double (*g_func_input)(double *f, double *w, int M), double *gW_input) 
{
	double*	lowBound = Problem_getLowerBound ();
	double*	uppBound = Problem_getUpperBound ();
	double 	delta 	= 0;

	// init g_func and gW
	g_func 	= g_func_input;
	gW 	= gW_input;

	// set delta
	delta = (1.0 + randu ()) * (1.0e-3) * (uppBound[i] - lowBound[i]);

	// 1.2.1 init the three points
	memcpy (x+1*numVar, x+0*numVar, numVar*sizeof (double));
	memcpy (x+2*numVar, x+0*numVar, numVar*sizeof (double));
	memcpy (y+1*numObj, y+0*numObj, numObj*sizeof (double));
	memcpy (y+2*numObj, y+0*numObj, numObj*sizeof (double));

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
}

//
void tps_exec (double *x, int numVar, double *y, int numObj, int i, int maxFE_input) {
	tps (x, numVar, y, numObj, i, maxFE_input);
}
