package Local::JSONParser;

use JSON::XS;
use strict;
use Unicode::Escape 'unescape';
use warnings;
use base qw(Exporter);
our @EXPORT_OK = qw( parse_json );
our @EXPORT = qw( parse_json );
use DDP;

sub encodeToText {
	#преобразуем все спец символы в действительно специальные
	my $string = shift();
	$string =~ s/\\b/\b/g;
	$string =~ s/\\f/\f/g;
	$string =~ s/\\n/\n/g;
	$string =~ s/\\r/\r/g;
	$string =~ s/\\t/\t/g;
	$string =~ s/\\\//\//g;
	$string =~ s/\\"/"/g;
	#$string =~ s/\\//g;
	
	return unescape($string);
}

sub parse_json {
	my $source = shift;
	$source =~ s/\n//gm;
	my ($firstChar) = ($source =~ /([\[|\{])/);
	
	#Смотрим на "первый" символ строки, это либо { либо [
	#В зависимости от него мы начинаем обрабатывать выражение (как массив или как объект)
	if ($firstChar eq "[") {
		#array
		#удалим окаймляющие скобки, и добавим к концу (,) что бы выражение имело вид:
		# elem1, elem2, elem3, ... , elemN, (так будет удобнее разбивать по элементам)
		$source =~ s/([\[|\{])//;
		$source =~ s/(.*)([\]|\}])/$1/;
		$source .= ",";
		my @result;
		while ($source =~ m{
			(
				#Шаблон для string
				("(?:[^"\\]|\\(?:["\\\/bfnrt]|(?:u\d{4})))+")\s*,
				|
				#Шаблон для number
				((?:\-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE](?:\+|\-)?\d+)?))\s*,
				|
				#Шаблон для объекта
				(\{.*\})\s*,
				|
				#Шаблон для массива
				(\[.*\])\s*,
			)
			}gxm) {
			my ($string, $number, $object, $array) = ($2, $3, $4, $5);
			#ищем отдельные элементы массива, если они "элементарные", то сразу добавляем
			#иначе запускаемся рекурсивно дальше
			if ($string) {
				$string =~ s/^"//;
				$string =~ s/"$//;
				#удаляем кавычки у строки, спереди и сзади
				#"превращаем" спец символы в действительно спецсимволы
				$string = encodeToText($string);
				push(@result, $string);
			} elsif ($number) {
				push(@result, $number);
			} elsif ($object) {
				push(@result, parse_json($object));
			} elsif ($array) {
				push(@result, parse_json($array));
			}
		}
		return \@result;
	} else {
		# Делаем все тоже самое, как и с массивом, только теперь элементы имеют
		# вид string: value
		#object
		$source =~ s/([\[|\{])//;
		$source =~ s/(.*)([\]|\}])/$1/;
		$source .= ",";
		my %result;
		while ($source =~ m{
			#Шаблон для string (key)
			("(?:[^"\\]|\\(?:["\\\/bfnrt]|(?:u\d{4})))+")
			\s*\:\s*
			(
				(?:
					#Шаблон для string
					("(?:[^"\\]|\\(?:["\\\/bfnrt]|(?:u\d{4})))+")
					|
					#Шаблон для number
					((?:\-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE](?:\+|\-)?\d+)?))
					|
					#Шаблон для object
					(\{.*\})
					|
					#Шаблон для array
					(\[.*\])
				)
			)\s*,
			}xgm) {
			my ($path, $string, $number, $object, $array) = ($1, $3, $4, $5, $6);
			$path =~ s/^"//;
			$path =~ s/"$//;
			$path = encodeToText($path);
			print "string: $string \n";
			if ($string) {
				$string =~ s/^"//;
				$string =~ s/"$//;
				$string = encodeToText($string);
				$result{$path} = $string;
			} elsif ($number) {
				$result{$path} = $number;
			} elsif ($object) {
				$result{$path} = parse_json($object);
			} elsif ($array) {
				$result{$path} = parse_json($array);
			}
		}
		return \%result;
	}
	
	
	#return JSON::XS->new->utf8->decode($source);
	return {};
}
#p(parse_json('[1,2,"\u0451"]'));
#p(parse_json('{ "key1":"string \u0451 \n value","key2":-3.1415,"key3": ["nested array"],"key4":{"nested":"object"}}'));
#p(parse_json('{"key1":"value"}'));
1;
