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

my $it = Local::Iterator::Mixer->new(
	iterators => [
		Local::Iterator::Rewindable::Array->new(array => [1,2,3]),
		Local::Iterator::Rewindable::Array->new(array => [4,5,6,7,8,9]),
		Local::Iterator::Rewindable::Array->new(array => [10,11,12,13]),
	],
);

my $ret = $it -> all();

p $ret;

=cut
\ [
    [0]  1,
    [1]  4,
    [2]  10,
    [3]  2,
    [4]  5,
    [5]  11,
    [6]  3,
    [7]  6,
    [8]  12,
    [9]  7,
    [10] 13,
    [11] 8,
    [12] 9
]
=cut
