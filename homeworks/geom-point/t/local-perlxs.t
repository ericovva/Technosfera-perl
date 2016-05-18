# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Local-perlxs.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok('Local::perlxs') };
my $point1 = {x => 1, y => 1};
my $circle = {x => 1, y => 3, r => 1};
is(Local::perlxs::distance_to_sircle($point1, $circle), 1);
is_deeply(Local::perlxs::cross_point_sircle($point1, $circle), {x=>1, y=>2});
#########################
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

