#!/usr/bin/env perl
package bin::music_library;
use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use lib '/home/gmoryes/Technosfera-perl/homeworks/music_library/lib/';
 
use Local::Parse qw(parse get_SORT get_COLUMNS);
use Local::Sort qw(sort_hash);
use Local::PrintTable qw(print_table);

my %list = %{parse()};
my $sortFromKey = get_SORT();
my $columnsFromKey = get_COLUMNS();
my @order = (0..scalar(keys %list) - 1);
if ($sortFromKey) {
	@order = @{sort_hash(\%list, \@order, $sortFromKey)};
}
print_table($columnsFromKey, \%list, \@order);






