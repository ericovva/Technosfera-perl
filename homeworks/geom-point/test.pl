use Local::perlxs ':all';
use mult_matrix 'mult_perl';
use DDP;

my ($arr1, $arr2);
for my $i (0..20) {
	for my $j (0..20) {
		$arr1->[$i][$j] = $i * $j;
		$arr2->[$i][$j] = $i / ($j + 100);
	}
}

my $time = time;
my $res = mult($arr1, $arr2);
print "C: ".(time - $time)."\n";;
$res = mult_perl($arr1, $arr2);
print "Perl: ".(time - $time)."\n";

my $point = {"x" => 1, "y" => 1};
my $sircle = {"x" => 0, "y" => 0, "r" => 1};
my $dist = distance_to_sircle($point, $sircle);
p $dist;
$dist = cross_point_sircle($point, $sircle);
p $dist;
