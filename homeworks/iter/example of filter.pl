use lib '/home/gmoryes/Technosfera-perl/homeworks/iter/lib';
use Local::Iterator::Array;
use DDP;
use strict;
use Local::Iterator::File;
use Local::Iterator::Aggregator;
use Local::Iterator::Concater;
use Local::Iterator::Map;
use Local::Iterator::Interval;
use Local::Iterator::Filter;
use DateTime;
use DateTime::Duration;

my $iterator = Local::Iterator::Filter->new(
	iterator => Local::Iterator::Array->new(array => [1,2,3,4,5]),
);

my $ret = $iterator->filter(
	sub {
		my $var = shift;
		return 0 if $var % 2 == 0;
		return 1;
	}
);

p $ret;

