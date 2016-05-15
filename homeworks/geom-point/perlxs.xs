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

double distance_point(x1,y1,x2,y2)
    double x1
    double y1
    double x2
    double y2

    CODE:
    double ret;
    ret = sqrt( pow(x1-x2, 2) + pow(y1-y2, 2) );
    RETVAL = ret;

    OUTPUT:
    RETVAL

void distance_ext_point(x1,y1,x2,y2)
    double x1
    double y1
    double x2
    double y2

    PPCODE:
    double dx = fabs(x1-x2);
    double dy = fabs(y1-y2);
    double dist = sqrt( pow(dx, 2) + pow(dy, 2) );

    PUSHs(sv_2mortal(newSVnv(dist)));
    PUSHs(sv_2mortal(newSVnv(dx)));
    PUSHs(sv_2mortal(newSVnv(dy)));

double distance_call_point()
    PPCODE:
    int count;
    double x1, y1, x2, y2;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    PUTBACK;
    count = call_pv("Local::perlxs::get_points", G_ARRAY|G_NOARGS);

    SPAGAIN;
    if (count != 4) croak("call get_points trouble\n");
    x1 = POPn;
    y1 = POPn;
    x2 = POPn;
    y2 = POPn;
    double dist = sqrt( pow(x1-x2, 2) + pow(y1-y2, 2) );
    FREETMPS;
    LEAVE;
    PUSHs(sv_2mortal(newSVnv(dist)));

double distance_call_arg_point()
    PPCODE:
    int count;
    double x1, y1, x2, y2;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(1)));
    PUTBACK;
    count = call_pv("Local::perlxs::get_points", G_ARRAY);
    SPAGAIN;
    if (count != 2) croak("call get_points trouble\n");
    x1 = POPn;
    y1 = POPn;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(2)));
    PUTBACK;
    count = call_pv("Local::perlxs::get_points", G_ARRAY);
    SPAGAIN;
    if (count != 2) croak("call get_points trouble\n");
    x2 = POPn;
    y2 = POPn;

    double dist = sqrt( pow(x1-x2, 2) + pow(y1-y2, 2) );
    FREETMPS;
    LEAVE;
    PUSHs(sv_2mortal(newSVnv(dist)));

double distance_pointobj(r_point1, r_point2)
    SV *r_point1
    SV *r_point2
    PPCODE:
    double x1,y1,x2,y2;
    SV **_x1, **_y1, **_x2, **_y2, *_point1, *_point2;
    HV *point1, *point2;
    if(!(SvOK(r_point1) && SvROK(r_point1) && SvOK(r_point2) && SvROK(r_point2))){
        croak("Point must be a hashref");
    }
    _point1 = SvRV(r_point1); _point2 = SvRV(r_point2);
    if( SvTYPE(_point1) != SVt_PVHV || SvTYPE(_point2) != SVt_PVHV){
        croak("Point must be a hashref");
    }
    point1 = (HV*)_point1; point2 = (HV*)_point2;
    if(!(hv_exists(point1, "x", 1) && hv_exists(point2, "x", 1) && 
            hv_exists(point1, "y", 1) && hv_exists(point2, "y", 1))){
        croak("Point mush contain x and y keys");
    }
    _x1 = hv_fetch(point1, "x", 1, 0); _y1 = hv_fetch(point1, "y", 1, 0);
    _x2 = hv_fetch(point2, "x", 1, 0); _y2 = hv_fetch(point2, "y", 1, 0);
    if( !(_x1 && _x2 && _y1 && _y2)){ croak("Non allow NULL in x and y coords"); }
    x1 = SvNV(*_x1); x2 = SvNV(*_x2);
    y1 = SvNV(*_y1); y2 = SvNV(*_y2);
    PUSHs(sv_2mortal(newSVnv(sqrt( pow(x1-x2,2) + pow(y1-y2,2)))));


double distance_pointstruct(point1, point2)
    GEOM_POINT *point1
    GEOM_POINT *point2
    CODE:
    double ret;
    ret = sqrt( pow(point1->x-point2->x,2) + pow(point1->y-point2->y,2));
    free(point1);
    free(point2);
    RETVAL = ret;
    OUTPUT:
    RETVAL
    
    
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
		
		
	
