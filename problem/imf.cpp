#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include "imf.h"
#include "zdt.h"
#include "dtlz.h"
#include "lsmop.h"
#include "matrix.h"
#include "shape.h"

#define PI 3.14159265358979323846264338327950288419716939937510
#define pi 3.14159265358979323846264338327950288419716939937510
#define NUM_SAMPLE 1.0e+4

// test problem
static Problem_t *P;

// 
static void  imf1 (double *x, int n, double *f, int m);
static void  imf2 (double *x, int n, double *f, int m);
static void  imf3 (double *x, int n, double *f, int m);
static void  imf4 (double *x, int n, double *f, int m);
static void  imf5 (double *x, int n, double *f, int m);
static void  imf6 (double *x, int n, double *f, int m);
static void  imf7 (double *x, int n, double *f, int m);
static void  imf8 (double *x, int n, double *f, int m);
static void  imf9 (double *x, int n, double *f, int m);
static void  imf10 (double *x, int n, double *f, int m);

Problem_t* IMF_new (char *title, int numObj, int numVar) {
	// common variable
	int 	i;
	size_t 	size;
	double*	lowBound = NULL; 
	double* uppBound = NULL;

	// allocating memory for a problem
        Problem_t *problem = (Problem_t *)malloc (sizeof (Problem_t));
        if (problem == NULL) {
        	fprintf (stderr, "Allocating memory failed\n");         
               	exit (-1);
        }
	strcpy (problem->title, title);
	problem->numObj = 2; 
	problem->numVar = numVar;
	if (!strcmp (title, "IMF4") || !strcmp (title, "IMF8")) {
		problem->numObj = 3; 
	}
	
	// setting the bound of varibles
	size = numVar * sizeof (double);
	lowBound = (double *)malloc (size);
	uppBound = (double *)malloc (size);
	for (i=0; i<numVar; i++) {
		lowBound[i] = 0.0;
		uppBound[i] = 1.0;
	}
	if (!strcmp (title, "IMF9") || !strcmp (title, "IMF10")) {
		lowBound[0] = 0.0;
		uppBound[0] = 1.0;
		for (i=1; i<numVar; i++) {
			lowBound[i] = 0.0;
			uppBound[i] = 10.0;
		}
	}
	problem->lowBound = lowBound;
	problem->uppBound = uppBound;

	// 
	if (!strcmp (title, "IMF1")) {
		P = problem; problem->evaluate = imf1;
	} else if (!strcmp (title, "IMF2")) {
		P = problem; problem->evaluate = imf2;
	} else if (!strcmp (title, "IMF3")) {
		P = problem; problem->evaluate = imf3;
	} else if (!strcmp (title, "IMF4")) {
		P = problem; problem->evaluate = imf4;
	} else if (!strcmp (title, "IMF5")) {
		P = problem; problem->evaluate = imf5;
	} else if (!strcmp (title, "IMF6")) {
		P = problem; problem->evaluate = imf6;
	} else if (!strcmp (title, "IMF7")) {
		P = problem; problem->evaluate = imf7;
	} else if (!strcmp (title, "IMF8")) {
		P = problem; problem->evaluate = imf8;
	} else if (!strcmp (title, "IMF9")) {
		P = problem; problem->evaluate = imf9;
	} else if (!strcmp (title, "IMF10")) {
		P = problem; problem->evaluate = imf10;
	} else { 
		fprintf (stderr, "error: %s is undefined\n", title);
		exit (0);
	}

	return problem;
}

static void  imf1 (double *x, int n, double *f, int m) {
	double 	g = 0, t = 0;
	int 	i;

	// f1
	f[0] = x[0];

	// g
	for (i=1, g=0; i<n; i++) {
		t = (1.0 + 5.0*(i+1.0)/n)*x[i] - x[0];
		g += t*t;
	}
	g = 1.0 + 9.0 * g / (n - 1);

	// f2
	f[1] = g * (1.0 - sqrt (f[0]/g));
}

static void  imf2 (double *x, int n, double *f, int m) {
	double 	g = 0, t = 0;
	int 	i;

	// f1
	f[0] = x[0];

	// g
	for (i=1, g=0; i<n; i++) {
		t = (1.0 + 5.0*(i+1.0)/n)*x[i] - x[0];
		g += t*t;
	}
	g = 1.0 + 9.0 * g / (n - 1);

	// f2
	f[1] = g * (1.0 - (f[0]*f[0])/(g*g));
}

static void  imf3 (double *x, int n, double *f, int m) {
	double 	g = 0, t = 0;
	int 	i;

	// f1
	f[0] = 1.0-exp(-4.0*x[0])*pow(sin(6*PI*x[0]),6);

	// g
	for (i=1, g=0; i<n; i++) {
		t = (1.0 + 5.0*(i+1.0)/n)*x[i] - x[0];
		g += t*t;
	}
	g = 1.0 + 9.0 * g / (n - 1);

	// f2
	f[1] = g * (1.0 - (f[0]*f[0])/(g*g));
}

static void  imf4 (double *x, int n, double *f, int m) {
	double 	g = 0, t = 0;
	int 	i;

	// g
	for (i=2, g=0; i<n; i++) {
		t = (1.0 + 5.0*(i+1.0)/n)*x[i] - x[0];
		g += t*t;
	}

	// f1, f2, f3
	f[0] = cos(0.5*PI*x[0]) * cos(0.5*PI*x[1]) * (1 + g);
	f[1] = cos(0.5*PI*x[0]) * sin(0.5*PI*x[1]) * (1 + g);
	f[2] = sin(0.5*PI*x[0]) * (1 + g);
}

static void  imf5 (double *x, int n, double *f, int m) {
	double 	g = 0, t = 0;
	int 	i;

	// f1
	f[0] = x[0];

	// g
	for (i=1, g=0; i<n; i++) {
		t = pow(x[i],1.0/(1.0+3.0*(i+1.0)/n)) - x[0];
		g += t*t;
	}
	g = 1.0 + 9.0 * g / (n - 1);

	// f2
	f[1] = g * (1.0 - sqrt (f[0]/g));
}

static void  imf6 (double *x, int n, double *f, int m) {
	double 	g = 0, t = 0;
	int 	i;

	// f1
	f[0] = x[0];

	// g
	for (i=1, g=0; i<n; i++) {
		t = pow(x[i],1.0/(1.0+3.0*(i+1.0)/n)) - x[0];
		g += t*t;
	}
	g = 1.0 + 9.0 * g / (n - 1);

	// f2
	f[1] = g * (1.0 - (f[0]*f[0])/(g*g));
}

static void  imf7 (double *x, int n, double *f, int m) {
	double 	g = 0, t = 0;
	int 	i;

	// f1
	f[0] = 1.0-exp(-4.0*x[0])*pow(sin(6*PI*x[0]),6);

	// g
	for (i=1, g=0; i<n; i++) {
		t = pow(x[i],1.0/(1.0+3.0*(i+1.0)/n)) - x[0];
		g += t*t;
	}
	g = 1.0 + 9.0 * g / (n - 1);

	// f2
	f[1] = g * (1.0 - (f[0]*f[0])/(g*g));
}

static void  imf8 (double *x, int n, double *f, int m) {
	double 	g = 0, t = 0;
	int 	i;

	// g
	for (i=2, g=0; i<n; i++) {
		t = pow(x[i],1.0/(1.0+3.0*(i+1.0)/n)) - x[0];
		g += t*t;
	}

	// f1, f2, f3
	f[0] = cos(0.5*PI*x[0]) * cos(0.5*PI*x[1]) * (1 + g);
	f[1] = cos(0.5*PI*x[0]) * sin(0.5*PI*x[1]) * (1 + g);
	f[2] = sin(0.5*PI*x[0]) * (1 + g);
}

static void  imf9 (double *x, int n, double *f, int m) {
	double 	g = 0, t = 0;
	double	g1, g2;
	int 	i;

	// f1
	f[0] = x[0];

	// g
	for (i=1, g=0, g1=0, g2=1; i<n; i++) {
		t = pow(x[i],1.0/(1.0+3.0*(i+1.0)/n)) - x[0];
		g1 += t*t;
		g2 *= cos(t/sqrt(i-0.0));
	}
	g = g1 / 4000 - g2 + 2;

	// f2
	f[1] = g * (1.0 - sqrt (f[0]/g));
}

static void  imf10 (double *x, int n, double *f, int m) {
	double 	g = 0, t = 0;
	int 	i;

	// f1
	f[0] = x[0];

	// g
	for (i=1, g=0; i<n; i++) {
		t = pow(x[i],1.0/(1.0+3.0*(i+1.0)/n)) - x[0];
		g += t*t - 10*cos(2*PI*t);
	}
	g = 1 + 10*(n-1) + g;

	// f2
	f[1] = g * (1.0 - sqrt (f[0]/g));
}


//**************************************************************************************************************
//**************************************************************************************************************

Matrix_t* IMF_sample (int No, int numObj) {
	switch (No) {
		case 1:
		case 5:
		case 9:
		case 10:
			return	ZDT_sample (1, 2);
		case 2:
		case 6:
			return	ZDT_sample (2, 2);
		case 3:
		case 7:
			return	ZDT_sample (6, 2);
		case 4:
		case 8:
			return	DTLZ_sample (2, 3);
		default:
                       fprintf (stderr, "IMF%d_sample have been not implemented now\n", No);
                       exit (0);
	}
	return NULL;
}

