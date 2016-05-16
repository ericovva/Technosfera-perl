#include <EXTERN.h>
#include <perl.h>
#include <stdio.h>

static PerlInterpreter *my_perl;

/* "Real programmers can write assembly code in any language." */

void error_tmpl(char *message) {
    fprintf(stderr, "%s\n", message);
    exit(1);
}

void statistic() {
	printf("\n");
	HV *hash;
	hash = get_hv("Plugin::state", 0);
	if (!hash) error_tmpl("end");
	HE* value;
	char * key;
	int len;
	hv_iterinit(hash);
	while (value = hv_iternext(hash)) {
		int val = SvIV(HeVAL(value));
		key = hv_iterkey(value, &len);
		printf("%s => %d \n", key, val);
	}
}

static void call_func(char *func_name, int argv, char **argc )
{
    int count, f;
    dSP;                            /* initialize stack pointer         */
    ENTER;                          /* everything created after here    */
    SAVETMPS;                       /* ...is a temporary variable.      */
    PUSHMARK(SP);                   /* remember the stack pointer       */
    for(f=0;f<argv; f++ ){          /* push args onto the stack         */
        XPUSHs(sv_2mortal(newSVpv(argc[f], strlen(argc[f]))));
    }
    PUTBACK;                        /* make local stack pointer global  */
    count = call_pv(func_name, G_SCALAR|G_EVAL); /* call the function   */
    SPAGAIN;                        /* refresh stack pointer            */
    PUTBACK;
    if (SvTRUE(ERRSV)){             /* check on die                     */
        error_tmpl(SvPV_nolen(ERRSV));
    }
    else{
        if (count != 1)             /* check count var in stack         */
            error_tmpl("Perl callback must return 1 parameter");
        printf ("%s", POPp);        /* pop the return value from stack  */
    }
    FREETMPS;                       /* free that return value           */
    LEAVE;                          /* ...and the XPUSHed "mortal" args */
}
static char encoding_table[] = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
                                'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
                                'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
                                'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
                                'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
                                'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
                                'w', 'x', 'y', 'z', '0', '1', '2', '3',
                                '4', '5', '6', '7', '8', '9', '+', '/', '='};

char * Read(FILE * fh, int *n) {
	int maxi = 100;
	char * str = (char*) malloc(sizeof(char) * maxi);
	*n = 0;
	char c;
	while (!feof(fh)) {
		fscanf(fh, "%c", &c);
		str[*n] = c;
		(*n)++;
		if (*n == maxi) {
			str = (char*) realloc(str, 2 * maxi);
			maxi *= 2;
		}
	}
	(*n) -= 2;
	return str;
}
int find_code(char c) {
	int i;
	for (i = 0; i < sizeof(encoding_table) / sizeof(char); i++) {
		if (encoding_table[i] == c) return i;
	}
	return -1;
}
char * base64_encode(char * str, int len, int* out_len) {
	int i = 0;
	char* res = (char*)malloc(sizeof(char) * (3 * len) / 4);
	(*out_len) = 0;
	for (i = 0; i < len; i += 4) {
		char a = str[i], b = str[i + 1], c = str[i + 2], d = str[i + 3];
		a = (char) find_code(a); b = (char) find_code(b);
		c = (char) find_code(c); d = (char) find_code(d);
		if (c != 64 && d != 64) {
			char A = (a << 2) + ((b & 0x30) >> 4);
			char B = ((b & 0xF) << 4) + (c >> 2);
			char C = ((c & 0x3) << 6) + d;
			//printf("%c%c%c", A, B, C);
			res[(*out_len)++] = A;
			res[(*out_len)++] = B;
			res[(*out_len)++] = C;
		} else if(c != 64) {
			char A = (a << 2) + ((b & 0x30) >> 4);
			char B = ((b & 0xF) << 4) + (c >> 2);
			//printf("%c%c", A, B);
			res[(*out_len)++] = A;
			res[(*out_len)++] = B;
		} else {
			char A = (a << 2) + ((b & 0x30) >> 4);
			//printf("%c", A);
			res[(*out_len)++] = A;
		}
	}
	return res;
}
int main (int argc, char **argv, char **env)
{
    char *include_dir, *module;
    FILE *template;
    char *str, *buf, *found, *p_func, *arg_begin, *arg_end, tmp, *func_name, **args, *pkg_name, *var_name;
    int in_tag = 0, cur_param = 0, f, exitstatus = 0;
	const int max_params = 10;

    include_dir = malloc(sizeof(char)*strlen(argv[3])+3);
    module = malloc(sizeof(char)*strlen(argv[1])+3);
    strcpy(include_dir, "-I");
    strcat(include_dir, argv[3]);
    strcpy(module, "-M");
    strcat(module, argv[1]);

    char *perl_argv[] = { "", module, include_dir, "-e0" };

    pkg_name = malloc(sizeof(char)*strlen(argv[1]));
    strncpy(pkg_name, argv[1], strlen(argv[1]));
    strcat(pkg_name, "::");
    args = malloc(sizeof(int)*max_params);
    
    PERL_SYS_INIT3(&argc,&argv,&env);
    my_perl = perl_alloc();
    perl_construct( my_perl );
    exitstatus = perl_parse(my_perl, NULL, 4, perl_argv, (char **)NULL);
    if(exitstatus){
        exit(exitstatus);
    }
    exitstatus = perl_run(my_perl);

	FILE * fh = fopen(argv[2], "r");
	int n;
	int m;
	char * strin = Read(fh, &n);
	char * res = base64_encode(strin, n, &m);
	printf("%s", res);
	call_func("Plugin::parse", 1, &res);
    statistic();
    free(pkg_name);
    free(args);
    perl_destruct(my_perl);
    perl_free(my_perl);
}
