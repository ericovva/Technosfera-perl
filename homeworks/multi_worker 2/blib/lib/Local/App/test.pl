
use warnings;
use DDP;
use JSON::XS;
use Data::Dumper;
use lib '/home/gmoryes/Technosfera-perl/homeworks/multi_worker/lib';
my $f = "abc.txt";
if (-e $f) {
	open($f, '+<', "abc.txt");
} else {
	open($f, '>', 'abc.txt');
}
print $f "sd";
