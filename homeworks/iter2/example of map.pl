use DDP;
use lib '/home/gmoryes/Technosfera-perl/homeworks/iter/lib';
use strict;
use Local::Iterator::Rewindable::File;
use Local::Iterator::Rewindable::Array;
use Local::Iterator::Aggregator;
use Local::Iterator::Map;
use Local::Iterator::Interval;
use Local::Iterator::Filter;
use DateTime;
use DateTime::Duration;
use Local::Iterator::Mixer;


my $it = Local::Iterator::Map->new(
	iterator => Local::Iterator::Rewindable::Array->new(array => [1,2,3,4]),
	callback => sub {
		my $var = shift;
		return $var * $var;
	},
);
my ($next, $end) = $it->next();
print "next: $next \n";
my $ret = $it->all();
p $ret;
$it->{"iterator"}->goToBegin();
$ret = $it->all();
p $ret;
=cut
next: 1 
\ [
    [0] 4,
    [1] 9,
    [2] 16
]
\ [
    [0] 1,
    [1] 4,
    [2] 9,
    [3] 16
]
=cut




