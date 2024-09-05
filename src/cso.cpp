#include "cso.h"
#include "myrandom.h"

void cso (double* xl, double* vl, double* xw, double* xn, double* vn, double* low, double* upp, int numVar) {
	double 	r0, r1;
	int	i;

	// r1, r2
	r0 = randu ();
	r1 = randu ();

	// update loser
	for (i=0; i<numVar; i++) {
		vn[i] = r0*vl[i] + r1*(xw[i] - xl[i]);
		xn[i] = xl[i] + vn[i] + r0*(vn[i] - vl[i]);

		//
		if (xn[i] > upp[i]) { xn[i] = upp[i];}
		if (xn[i] < low[i]) { xn[i] = low[i];}
	}
}
