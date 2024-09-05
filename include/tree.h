#ifndef _TREE_H 
#define _TREE_H

#include "problem.h"

Problem_t *TREE_new (char *title, int numObj, int numVar);
Matrix_t  *TREE_sample (int No, int numObj);

#endif
