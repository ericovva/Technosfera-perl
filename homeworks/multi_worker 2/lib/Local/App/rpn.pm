=head1 DESCRIPTION
Эта функция должна принять на вход арифметическое выражение,
а на выходе дать ссылку на массив, содержащий обратную польскую нотацию
Один элемент массива - это число или арифметическая операция
В случае ошибки функция должна вызывать die с сообщением об ошибке
=cut
package Local::App::rpn;
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
use Local::App::tokenize 'tokenize';
use Exporter 'import';
our @EXPORT = ('rpn');
sub isNum {
	my $check = shift;
	if ($check =~/\d+/) {
		return 1;
	} else {
		return 0;
	}	
}
sub rpn {
	my $expr = shift;
	my $source = tokenize($expr);
	my @res = @{$source};
	my @rpn = ();
	my @stack = ();
	my %lvl = (
		'U+' => 4,
		'U-' => 4,
		'^' => 3,
		'*' => 2,
		'/' => 2,
		'+' => 1,
		'-' => 1,
		'(' => 0,
		')' => 0,
	);
	my %isRight = (
		'U+' => 1,
		'U-' => 1,
		'^' => 1,
		'*' => 0,
		'/' => 0,
		'+' => 0,
		'-' => 0,
		'(' => 0,
		')' => 0,
	);
	my $len = -1;
	foreach my $i(@res) {
		if (isNum($i)) {
			push(@rpn, $i);
		} elsif (@stack == -1) {
			push(@stack, $i);
			$len++;
		} elsif ($i eq "(") {
			push(@stack, $i);
			$len++;
		} elsif ($i eq ")") {
			while ($stack[$len] ne "(") {
				push(@rpn, pop(@stack));
				$len--;
			}
			pop(@stack);
			$len--;
		} else {
			if ($isRight{$i} == 1) {
				#right
				while ($len != -1 && $lvl{$stack[$len]} > $lvl{$i} && ($stack[$len] !~/U[\+|-]/)) {
					push(@rpn, pop(@stack));
					$len--;
					if ($len == -1) {
						last;
					}
				}
				push(@stack, $i);
				$len++;
			} else {
				#left
				while ($len != -1 && $lvl{$stack[$len]} >= $lvl{$i}) {
					push(@rpn, pop(@stack));
					$len--;
					if ($len == -1) {
						last;
					}
				}
				push(@stack, $i);
				$len++;
			}
		}
	}
	while ($len != -1) {
		push(@rpn, pop(@stack));
		$len--;
	}
	#print(join(' ', @rpn));
	return \@rpn;
}
1;

