use lib '/home/gmoryes/Technosfera-perl/homeworks/iter/lib';


use DDP;
use strict;
use Local::Iterator::RewindableIterator::File;
use Local::Iterator::RewindableIterator::Array;
use Local::Iterator::Aggregator;
use Local::Iterator::Map;
use Local::Iterator::Interval;
use Local::Iterator::Filter;
use DateTime;
use DateTime::Duration;

my $it = Local::Iterator::Map->new(
	iterator => Local::Iterator::RewindableIterator::Array->new(array => [1,2,3,4]),
	callback => sub {
		my $var = shift;
		return $var * $var;
	},
);
my ($next, $end) = $it->next();
print "next: $next \n";
my $ret = $it->all();
p $ret;

#next: 1 
#\ [
#    [0] 4,
#    [1] 9,
#    [2] 16
#]

