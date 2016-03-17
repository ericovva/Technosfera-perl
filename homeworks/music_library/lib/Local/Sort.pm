=head
	Модуль, который получает на вход ссылку на hash песен, и возвращает
	порядок, в котором их нужно выводить \@order
	
=cut
package Local::Sort;
use strict;
use warnings;
use Data::Dumper;
use Exporter 'import';
our @EXPORT = ('sort_hash');
use lib '/home/gmoryes/Technosfera-perl/homeworks/music_library/lib/';
use Local::Parse 'get_SORT';
sub sort_hash {
	my %list = %{shift()};
	my @order = @{shift()};
	my $sortFromKey = shift();
	if ($sortFromKey eq "year") {
		@order = sort{(0 + $list{$a}{"$sortFromKey"}) <=> (0 + $list{$b}{"$sortFromKey"})} @order;
	} else {
		@order = sort{$list{$a}{"$sortFromKey"} cmp $list{$b}{"$sortFromKey"}} @order;
	}
	return \@order;
}
1;
