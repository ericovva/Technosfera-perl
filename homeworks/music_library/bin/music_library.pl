#!/usr/bin/env perl
package bin::music_library;
use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use lib '/home/gmoryes/Technosfera-perl/homeworks/music_library/lib/';
 
use Local::Parse qw(parse $SORT);
use Local::Sort qw(sort_hash);
use Local::PrintTable qw(print_table);

my %list = %{parse()};
my @order = ();
for (my $i = 0; $i < scalar(keys %list); $i++) {
	push(@order, $i);
}
if ($SORT) {
	@order = @{sort_hash(\%list, \@order)};
}
print_table(\%list, \@order);






