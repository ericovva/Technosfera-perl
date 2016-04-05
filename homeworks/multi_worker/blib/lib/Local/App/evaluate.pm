=head1 DESCRIPTION

Эта функция должна принять на вход ссылку на массив, который представляет из себя обратную польскую нотацию,
а на выходе вернуть вычисленное выражение

=cut
package Local::App::evaluate;
use 5.010;
use strict;
use Data::Dumper;
use warnings;
use diagnostics;
BEGIN{
	if ($] < 5.018) {
		package experimental;
		use warnings::register;
	}
}
no warnings 'experimental';

use lib '/home/gmoryes/Technosfera-perl/homeworks/multi_worker/lib';
use Local::App::rpn 'rpn';
use Exporter 'import';
our @EXPORT = ('evaluate');

sub evaluate {
	my $rpn_ = shift;
	my @rpn = @{$rpn_};
	my @stack = ();
	for my $i (@rpn) {
		if ($i !~/^\d+/) {
			#есть символы не числа
			if ($i ne 'U+' && $i ne 'U-') {
				my $prev1 = pop(@stack);
				my $prev2 = pop(@stack);
				#if ($i eq '-' || $i eq '+' || $i eq '*' || $i eq '/') {
				#	push(@stack, eval(" $prev2 ".$i." $prev1 "));
				if ($i eq '-') {
					push(@stack, $prev2 - $prev1);
				} elsif ($i eq '+') {
					push(@stack, $prev2 + $prev1);
				} elsif ($i eq '*') {
					push(@stack, $prev2 * $prev1);
				} elsif ($i eq '/') {
					push(@stack, $prev2 / $prev1);
				} else {
					push(@stack, $prev2 ** $prev1);
				}
			} else {
				if ($i eq 'U+') {
					#nothing..
				} else {
					push(@stack, -1 * pop(@stack));
				}
			}
		} else {
			push(@stack, $i);
		}
	}
	
	#print(pop(@stack));
	return pop(@stack);
}
1;
