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
use Local::Parse '$SORT';

sub sort_hash {
	my %list = %{shift()};
	my @order = @{shift()};
	if ($SORT eq "year") {
		@order = sort{(0 + $list{$a}{"$SORT"}) <=> (0 + $list{$b}{"$SORT"})} @order;
	} else {
		@order = sort{$list{$a}{"$SORT"} cmp $list{$b}{"$SORT"}} @order;
	}
	return \@order;
}
1;
