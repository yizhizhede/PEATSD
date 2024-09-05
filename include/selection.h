#ifndef _SELECTION_H 
#define _SELECTION_H

void select_by_RV (double* obj, int popSize, int numObj, double* V, int NR, double* L, double* zmin, int* sel);
void adapt_RV (double* obj, int popSize, int numObj, double*V, double* V0, int NR, double *L);

#endif
