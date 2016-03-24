package Local::JSONParser;

use utf8;
use JSON::XS;
use strict;
use Unicode::Escape 'unescape';
use Encode;
use warnings;
use base qw(Exporter);
our @EXPORT_OK = qw( parse_json );
our @EXPORT = qw( parse_json );
use DDP;

sub encodeToText {
	#преобразуем все спец символы в действительно специальные
	my $string = shift();
	if ($string eq "") {
		return $string;
	}
	$string = unescape($string);
	$string =~ s/\\b/\b/g;
	$string =~ s/\\f/\f/g;
	$string =~ s/\\n/\n/g;
	$string =~ s/\\r/\r/g;
	$string =~ s/\\t/\t/g;
	$string =~ s/\\\//\//g;
	$string =~ s/\\"/"/g;
	$string =~ s/\\\\/\\/g;
	
	return decode('utf8', $string);
}

sub numBracket {
	my @id = ();
	my $cnt = 1;
	my $source = shift;
	my @arr = split(//, $source);
	foreach my $i (@arr) {
		if ($i eq '[' or $i eq '{') {
			$i = $cnt.$i;
			push(@id, $cnt++);
		} elsif ($i eq ']' or $i eq '}') {
			$i = $i.pop(@id);
		}
	}
	return join('', @arr);
}
my $idBracket = 0;
sub parse_json {
	my $source = shift;
	$source =~ s/\n//gm;
	#Добавим id каждой скобки (чтобы в регулярном выражении правильно искать парные скобки)
	#[1,[1],3,{"key":0}] ==> 1[1,2[1]2,3,3{"key":0}3]1
	#Тогда чтобы найти парную скобку для 1[ будем искать ]1
	if (!$idBracket) {
		$source = numBracket($source);
		$idBracket = 1;
	}
	#print "source: $source \n";
	my ($firstChar) = ($source =~ /([\[|\{])/);
	#Смотрим на "первый" символ строки, это либо { либо [
	#В зависимости от него мы начинаем обрабатывать выражение (как массив или как объект)
	if ($firstChar eq '[') {
		#array
		#удалим окаймляющие скобки, и добавим к концу (,) что бы выражение имело вид:
		# elem1, elem2, elem3, ... , elemN, (так будет удобнее разбивать по элементам)
		
		$source =~ s/(\d+\[)//;
		$source =~ s/(.*)(\]\d+)/$1/;
		if (!$2) {
			#Если нет закрывающей - ошибка, неправильный баланс
			die "Bad balance";
		}
		my @result;
		my $copySource = $source;
		$copySource =~ s/\s*//gm;
		if (length($copySource) == 0) {
			return \@result;
		}
		$source .= ",";

		while ($source =~ s{
			(
				#Шаблон для объекта
				(?<object>(\d+)\{.*\}\3)\s*,
				|
				#Шаблон для массива
				(?<array>(\d+)\[.*\]\5)\s*,
				|
				#Шаблон для string
				(?<string>"(?:[^"\\]|\\(?:["\\\/bfnrt]|(?:u\d{4})))*")\s*,
				|
				#Шаблон для number
				(?<number>(?:\-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE](?:\+|\-)?\d+)?))\s*,
			)
			}{}xm) {
			my ($string, $number, $object, $array) = ($+{string}, $+{number}, $+{object}, $+{array});
			#ищем отдельные элементы массива, если они "элементарные", то сразу добавляем
			#иначе запускаемся рекурсивно дальше
			if ($string) {
				$string =~ s/^"//;
				$string =~ s/"$//;
				#удаляем кавычки у строки, спереди и сзади
				#"превращаем" спец символы в действительно спецсимволы
				$string = encodeToText($string);
				push(@result, $string);
			} elsif ($object) {
				push(@result, parse_json($object));
			} elsif ($array) {
				push(@result, parse_json($array));
			} elsif ($number or $number == 0) {
				push(@result, $number);
			}
		}
		$source =~ s/\s*//g;
		if (length($source) != 0) {
			#Если в результате осталось что-то кроме пробелов - ошибка (было что-то не по синтаксису)
			die "Wrong syntax in array";
		}
		return \@result;
	} elsif ($firstChar eq '{') {
		# Делаем все тоже самое, как и с массивом, только теперь элементы имеют
		# вид string: value
		#object
		
		$source =~ s/(\d+\{)//;
		$source =~ s/(.*)(\}\d+)/$1/;
		if (!$2) {
			#Аналогично с обработкой массива
			die "Bad balance";
		}
		my %result;
		my $copySource = $source;    
		$copySource =~ s/\s*//gm;
		if (length($copySource) == 0) {
			return \%result;
		}
		$source .= ",";
		while ($source =~ s{
			#Шаблон для string (key)
			(?<path>"(?:[^"\\]|\\(?:["\\\/bfnrt]|(?:u\d{4})))+")
			\s*\:\s*
			(
				(?:
					#Шаблон для объекта
					(?<object>(\d+)\{.*\}\4)\s*
					|
					#Шаблон для массива
					(?<array>(\d+)\[.*\]\6)\s*
					|
					#Шаблон для string
					(?<string>"(?:[^"\\]|\\(?:["\\\/bfnrt]|(?:u\d{4})))*")\s*
					|
					#Шаблон для number
					(?<number>(?:\-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE](?:\+|\-)?\d+)?))\s*
				)
			)\s*,
			}{}xm) {
				
			my ($path, $string, $number, $object, $array) = ($+{path}, $+{string}, $+{number}, $+{object}, $+{array});
			$path =~ s/^"//;
			$path =~ s/"$//;
			$path = encodeToText($path);
			if ($string) {
				$string =~ s/^"//;
				$string =~ s/"$//;
				$string = encodeToText($string);
				$result{$path} = $string;
			} elsif ($object) {
				$result{$path} = parse_json($object);
			} elsif ($array) {
				$result{$path} = parse_json($array);
			} elsif ($number or $number == 0) {
				$result{$path} = $number;
			}
		}
		$source =~ s/\s*//g;
		if (length($source) != 0) {
			#Аналогично с обработкой массива
			die "Wrong syntax in object";
		}
		return \%result;
	} else {
		#Если изначально не было открывающей скобки, а на вход всегда должен подаваться либо [], либо {}
		#Выдаем ошибку
		die "Wrong input";
	}
	
	
	#return JSON::XS->new->utf8->decode($source);
	return {};
}
#p(parse_json('['));
#p(parse_json('[["31a\u0451sd", 123, [1,[[2]],3]]]'));
#p(parse_json('{ "key1": "string value", "key2": -3.1415, "key3": ["nested array"], "key4": { "nested": "object" } }'));
#p(parse_json('[{"key":"1223\t\u0451"}]'));
#p(parse_json(q/[{ "a":[ "\t\u0451\",","\"," ] }]/));
#p(parse_json('{ "key1":"string \u0451 \n value","key2":-3.1415,"key3": ["nested array"],"key4":{"nested":"object"}}'));
#p(parse_json('{"key1":"value"}'));
1;
