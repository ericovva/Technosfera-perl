
use warnings;
use DDP;
use JSON::XS;
use Data::Dumper;
use lib '/home/gmoryes/Technosfera-perl/homeworks/multi_worker/lib';
sub func {
	my $x = shift;
	if ($x == 0) {
		die "error \n";
	} else {
		return $x;
	}
}
my $v = 1;
eval {
	$v = 2;
	die "asd";
} or print "bla";
print $v;
