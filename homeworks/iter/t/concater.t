use strict;
use warnings;

use Test::More tests => 5;

use Local::Iterator::RewindableIterator::Array;
use Local::Iterator::RewindableIterator::Concater;

my $iterator = Local::Iterator::RewindableIterator::Concater->new(
    iterators => [
        Local::Iterator::RewindableIterator::Array->new(array => [1, 2]),
        Local::Iterator::RewindableIterator::Array->new(array => [3, 4]),
        Local::Iterator::RewindableIterator::Array->new(array => [5, 6]),
    ],
);

my ($next, $end);

($next, $end) = $iterator->next();
is($next, 1, 'next value');
ok(!$end, 'not end');

is_deeply($iterator->all(), [2, 3, 4, 5, 6], 'all');

($next, $end) = $iterator->next();
is($next, undef, 'no value');
ok($end, 'end');
