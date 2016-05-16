#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "const-c.inc"

typedef struct { double x, y; } GEOM_POINT;
typedef struct { double x, y, r; } GEOM_SIRCLE;
typedef struct { double** arr; int n, m;} MATRIX;

MODULE = Local::perlxs                PACKAGE = Local::perlxs                

INCLUDE: const-xs.inc

#include <math.h>

PROTOTYPES: DISABLE
    
double distance_to_sircle(point, sircle)
	GEOM_POINT *point
	GEOM_SIRCLE *sircle
	CODE:
	double ret;
	ret = fabs(sqrt((point->x - sircle->x) * (point->x - sircle->x) + (point->y - sircle->y) * (point->y - sircle->y)) - sircle->r);
	free(point);
	free(sircle);
	RETVAL = ret;
	OUTPUT:
	RETVAL
	
GEOM_POINT* cross_point_sircle(point, sircle)
	GEOM_POINT *point
	GEOM_SIRCLE *sircle
	CODE:
	if (sqrt((point->x - sircle->x) * (point->x - sircle->x) + (point->y - sircle->y) * (point->y - sircle->y)) < sircle->r) {
		croak("Point into sircle, no crossing");
	}
	GEOM_POINT* vec = malloc(sizeof(GEOM_POINT));
	vec->x = point->x - sircle->x;
	vec->y = point->y - sircle->y;
	double len = sqrt(vec->x * vec->x + vec->y * vec->y);
	vec->x *= sircle->r / len;
	vec->y *= sircle->r / len;
	free(point);
	free(sircle);
	RETVAL = vec;
	OUTPUT:
	RETVAL

MATRIX* mult(A, B)
//n k
//k m
	MATRIX* A
	MATRIX* B
	CODE:
		if (A->m != B->n) croak("Matrixes must be N x K and K x M");
		int i, j, k;
		MATRIX* C = (MATRIX*) malloc(sizeof(MATRIX));
		C->n = A->n;
		C->m = B->m;
		C->arr = (double**) malloc(sizeof(double*) * A->n);
		for (i = 0; i < A->n; i++) {
			C->arr[i] = (double*) malloc(sizeof(double) * B->m);
			for (j = 0; j < B->m; j++) {
				C->arr[i][j] = 0;
				for (k = 0; k < A->m; k++) {
					C->arr[i][j] += A->arr[i][k] * B->arr[k][j];
				}
			}
		}

		free(A);
		free(B);
		RETVAL = C;
		OUTPUT:
		RETVAL
		
		
	
