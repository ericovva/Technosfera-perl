package mult_matrix;
use strict;
use Exporter 'import';
use DDP;
our @EXPORT_OK = (qw(mult_perl));
sub mult_perl {
	my $arr1 = shift;
	my $arr2 = shift;
	my $n = scalar(@{$arr1});
	my $k1 = scalar(@{$arr1->[0]});
	my $k2 = scalar(@{$arr2});
	my $m = scalar(@{$arr2->[0]});
	if ($k1 != $k2) {
		die "Matrixes must be N x K and K x M";
	}
	my $res;
	for my $i (0..$n - 1) {
		for my $j (0..$m - 1) {
			$res->[$i][$j] = 0;
			for my $k (0..$k1 - 1) {
				$res->[$i][$j] += $arr1->[$i][$k] * $arr2->[$k][$j];
			}
		}
	}
	return $res;
}

my $arr1 = [[1,2,3,4],[1,2,3,4],[1,2,3,4]];
my $arr2 = [[1,2,3],[1,2,3],[1,2,3],[1,2,3]];
#my $res = mult($arr1, $arr2);
#p $res;
