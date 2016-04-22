
=head1 DESCRIPTION
Эта функция должна принять на вход арифметическое выражение,
а на выходе дать ссылку на массив, состоящий из отдельных токенов.
Токен - это отдельная логическая часть выражения: число, скобка или арифметическая операция
В случае ошибки в выражении функция должна вызывать die с сообщением об ошибке
Знаки '-' и '+' в первой позиции, или после другой арифметической операции стоит воспринимать
как унарные и можно записывать как "U-" и "U+"
Стоит заметить, что после унарного оператора нельзя использовать бинарные операторы
Например последовательность 1 + - / 2 невалидна. Бинарный оператор / идёт после использования унарного "-"
=cut
package Local::App::tokenize;
use 5.010;
use strict;
use warnings;
use Data::Dumper;
use DDP;
use Exporter 'import';
our @EXPORT = ('tokenize');
use diagnostics;
BEGIN{
	if ($] < 5.018) {
		package experimental;
		use warnings::register;
	}
}
no warnings 'experimental';
sub isDigit {
	chomp(my $check = shift);
	return ($check =~/[0-9]/);
}
sub isBalance {
	chomp(my $check = shift);
	my @arr = split //, $check;
	my $balance = 0;
	for (my $i = 0; $i < scalar(@arr); $i++) {
		if ($arr[$i] eq "(") {
			$balance++;
		} elsif ($arr[$i] eq ")") {
			$balance--;
		}
		if ($balance < 0) {
			return 0;
		}
	}
	return !(!!$balance); 
	#!! = 0, если был 0, и 1 если был не 0, третье даст наоборот
}
my @res_ = ();
my @res = ();

sub getNum {
	my $i = shift;
	my $pow = shift;
	my $bad = 0;
	my $res = 0;
	if (!isDigit($res_[$i])) {
		$bad = 1;
		return ($i, $res, $bad);
	}
	if ($pow == 10) {
		while (isDigit($res_[$i])) {
			$res *= 10;
			$res += $res_[$i];
			$i++;
			if ($i == scalar(@res_)) {
				last;
			}
		}
	} else {
		while (isDigit($res_[$i])) {
			$res += $res_[$i] * $pow;
			$pow *= 0.1;
			$i++;
			if ($i == scalar(@res_)) {
				last;
			}
		}
	}
	$i--;
	return ($i, $res, $bad);
}

sub tokenize {
	@res = ();
	@res_ = ();
	chomp(my $expr = shift);
	
	$expr = "(".$expr;
	$expr .= ")";
	if (!isBalance($expr)) {
		die "Неправильный баланс скобок";
	}
	$expr=~s/(\s)+/ /g; #оставить только один пробел из повторения
	#есть место вида "(выражение)|ничего|выражение")
	if ($expr =~s/(\d)\s(\d)//g) {
		#num an num
		die "Нет операций между выражениями ".$1. " и ".$2."";
	} elsif ($expr =~s/(\([0-9\s\*\+\-\/\^e\.]*\))\s?(\([0-9\s\*\+\-\/\^e\.]*\))//g) {
		#(...) (...)
		die "Нет операций между выражениями ".$1." и ".$2."";
	} elsif ($expr =~s/(\d+)\s?(\([0-9\s\*\+\-\/\^e\.]*\))//g) {
		#число и скобки
		die "Нет операций между выражениями ".$1." и ".$2."";
	} elsif ($expr =~s/(\([0-9\s\*\+\-\/\^e\.]*\))\s?(\d+)//g) {
		#скобки и число
		die "Нет операций между выражениями ".$1." и ".$2."";
	}
	#удалим все пробелы
	$expr =~s/\s//g;
	if ($expr =~/([^0-9\+\-\(\)\^\*\/\.e])/) {
		die "Недопустимые символы: ".$1
	}
	#заменим все Xe+|-Y на [X * 10 ** +|-Y], [, ] у нас нет в записи
	#если что-то не заменилось, значит оно не подходит по синтаксису
	my @eres = ();
	while($expr =~m/(\d*\.?\d+)e([\+|-]?\d*\.?\d+)/g) {
		push(@eres, $1 * 10 ** $2);
	}
	@eres = reverse @eres;
	$expr =~s/(\d*\.?\d+)e([\+|-]?\d*\.?\d+)/[]/g;
	if ($expr =~/([^0-9\+\-\(\)\^\*\/\.\[\]])/) {
		die "Неправильный синтаксис с e: ".$1." : ";
	}
	@res_ = split //, $expr;
	for (my $i = 0; $i < scalar(@res_); $i++) {
		if ($res_[$i] eq "[") {
			push(@res, pop(@eres));
			$i++;
		} else {
			push(@res, $res_[$i]);
		}
	}
	@res_ = @res;
	@res = ();
	#соеденим все цифры
	push (@res, $res_[0]);
	my $flag = 0; #была ли число с точкой последним
	my $flage = 0;
	for (my $i = 1; $i < scalar(@res_); $i++) {
		if (isDigit($res_[$i])) {
			my @ans = ();
			if ($flag) {
				@ans = getNum($i, 0.1);
				#print "ans: @ans \n";
				$i = $ans[0];
				push(@res, pop(@res) + $ans[1]);
			} else {
				@ans = getNum($i, 10);
				$i = $ans[0];
				push(@res, $ans[1]);
			}
		} elsif ($res_[$i] eq ".") {
			if ($flag) {
				die "Неправильный синтаксис десятичного числа";
			}
			$flag = 1;
			if (!isDigit($res[scalar(@res) - 1])) {
				push(@res, 0);
			}
			#после точки обязательно цифра
			if ($i + 1 == scalar(@res_) || !isDigit($res_[$i + 1])) {
				die "Неправильный синтаксис десятичного числа";
			}
		} else {
			$flag = 0;
			push(@res, $res_[$i]);
		}
	}
	@res_ = ();
	push (@res_, "(");
	for (my $i = 1; $i < scalar(@res); $i++) {
		my $pr = $res[$i - 1];
		my $cur = $res[$i];
		push(@res_, $cur);
		if ($cur eq '+' || $cur eq '-') {
			if ($pr eq '^' || $pr eq '+' || $pr eq '-' || $pr eq '*' || $pr eq '/' || $pr eq '(') {
				#унарный оператор
				$res_[$i] = "U".$cur;
			}
		}
	}
	@res = @res_;
	for (my $i = 1; $i < scalar(@res) - 1; $i++) {
		#смотрим, верные ли операнды у бинарных операций
		if ($res[$i] !~/[^\+\-\*\/\^]/) {
			if ($res[$i - 1] =~/([^\d+\)\.])/) {
				die "Неверный операнд: \"".$1."\" перед ".$res[$i];
			}
			if ($res[$i + 1] =~/([^\d+|\(|U\+|U\-|\.])/) {
				die "Неверный операнд: \"".$1."\" после ".$res[$i];
			}
		}
		#верные ли операнды у унарных операций
		if ($res[$i] =~/U[\+\-]/) {
			if ($res[$i + 1] =~/([^\d+|\(|U\+|U\-|\.])/) {
				die "Неверный операнд: \"".$1."\" после ".$res[$i];
			}
		}
	}
	@res = @res[1..scalar(@res) - 2];
	#print(Dumper(@res));
	return \@res;
}
#p tokenize("1 + 3.12312412424124124 ^ 3.345");
1;
