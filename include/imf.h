#ifndef _IMF_H 
#define _IMF_H

#include "problem.h"

Problem_t *IMF_new (char *title, int numObj, int numVar);
Matrix_t  *IMF_sample (int No, int numObj);

#endif
