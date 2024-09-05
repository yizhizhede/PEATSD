#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "spcea.h"
#include "controller.h"

Population_t* spcea (Problem_t *problem) {	// Never stop EA
	int 	signal = 1;

	// 1. Initilize a population for the problem.
	Population20_t *P = Population20_new (problem);

	// 2. Poission process controll system and evolutionary algorithm.
	while (signal) {
		// 2.1 Get signal from Poisson process controll system. 
		signal = Controller (problem, P);
		
		// 2.2 Analysis the signal.
		switch (signal) {
			case CONTROL_RETURN: 
				control_return (P); 	break;
			case CONTROL_REPRODUCE:
				control_reproduce (P); 	break;
			case CONTROL_ELIMINATE:
				control_eliminate (P); 	break;
			case CONTROL_REPRODUCE_ELIMINATE:
				control_reproduce (P); 	
				control_eliminate (P); 	break;
			default:
				printf ("signal: %d has not defined\n", signal); 
				break;
		}
	}
	return NULL;
}
