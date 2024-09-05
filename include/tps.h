#ifndef _TPS_H 
#define _TPS_H

#include "population.h"

// three points search (tps)
void tps(double *x, int numVar, double *y, int numObj, int i, int maxFitness, double (*g_func)(double *f, double *w, int M), double *gW);

//
void tps_init (double *x, int numVar, double *y, int numObj, int i, double (*g_func)(double *f, double *w, int M),double *gW);
void tps_exec (double *x, int numVar, double *y, int numObj, int i, int maxFE);

#endif
