double** convert(AV * A) {
	int n = av_top_index(A);
	int m;
	int saveM = -1;
	int i = 0, j = 0;
	double** result = (double**) malloc(sizeof(double*) * n);
	for (i = 0; i <= n; i++) {
		SV **arr = av_fetch(A, i, 0);
		AV* subarr;
		subarr = (AV*) SvRV(*arr);
		m = av_top_index(subarr);
		if (saveM == -1) saveM = m;
		else {
			if (saveM != m) {
				croak("Matrix must be rectangular");
			}
		}
		for (j = 0; j <= m; j++) {
			result[j] = (double*) malloc(sizeof(double) * m);
			SV** elem = av_fetch(subarr, j, 0);
			if (!elem) croak("Elements must be not NULL");
			double element = SvNV(*elem);
			result[i][j] = element;
		}
	}
	return result;
}
