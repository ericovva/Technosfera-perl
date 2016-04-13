use lib '/home/gmoryes/Technosfera-perl/homeworks/iter/lib';
use Local::Iterator::Array;
use DDP;
use strict;
use Local::Iterator::File;
use Local::Iterator::Aggregator;
use Local::Iterator::Concater;
use Local::Iterator::Map;


my $it = Local::Iterator::Map->new(
	iterator => Local::Iterator::Array->new(array => [1,2,3,4]),
);

my $ret = $it->map(
	sub {
		my ($var) = @_;
		return $var * $var;
	}
);

p $ret;
	

