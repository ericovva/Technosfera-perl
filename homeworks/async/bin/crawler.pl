#!/usr/bin/env perl
use AnyEvent::HTTP;
use AE;
use Getopt::Long;
use HTML::Parser;
use DDP;
use 5.010;
use strict;
my %used;
my $cv = AE::cv;
$AnyEvent::HTTP::MAX_PER_HOST = 100;
my $all = 0;
my $maxi;
my $host;
my $help;
GetOptions("max=i" => \$maxi, "host=s" => \$host, "help" => \$help);
if (defined $help) {
	print "--max=1000 (Сколько ссылок найти)\n";
	print "--host=https://habrahabr.ru/ (Хост)\n";
	print "--filename=log.txt (Куда сохранить результат) \n";
	exit;
}
die "Нет max" if not defined $maxi;
die "Нет host" if not defined $host;
if ($host !~ /https?:\/\/(.*?)\..+/) {
	die "Неправильный синтаксис хоста";
}
my $host_name = $1;
p $host_name;
$| = 1;
sub len {
	my $x = shift;
	my $all = 0;
	while ($x > 0) {
		$all++;
		$x /= 10;
	}
	return $all;
}

sub check_and_add {
	my ($prev, $text) = @_;
	$text =~ s/\#(.*)//;
	return undef if not defined($text);
	if ($text =~ m/:\/\/(.*?)\./) {
		if ($1 ne $host_name) {
			return undef;
		} else {
			if (not exists($used{$text})) {
				return $text;
			} else {
				return undef;
				#say "already exists";
			}
		}
	} else {
		$text = substr($text, 1);
		$text = $prev.$text;
		if (not exists($used{$text})) {
			return $text;
		} else {
			return undef;
			#say "already exists";
		}
	}
	return undef;
}

my @top10_val = ();
my @top10_host = ();
sub add_into_res{
	my ($host, $value) = @_;
	if (@top10_val < 10) {
		push(@top10_val, $value);
		push(@top10_host, $host);
		return;
	} else {
		if ($top10_val[9] < $value) {
			pop @top10_val;
			pop @top10_host;
			push(@top10_val, $value);
			push(@top10_host, $host);
			my $i = 8;
			while ($i >= 0 and $top10_val[$i] < $top10_val[$i + 1]) {
				($top10_val[$i], $top10_val[$i + 1]) = ($top10_val[$i + 1], $top10_val[$i]);
				($top10_host[$i], $top10_host[$i + 1]) = ($top10_host[$i + 1], $top10_host[$i]);
				$i--;
			}
			return;
		} else {
			return;
		}
	}
}

sub print_next {
	$all++;
	print "$all / $maxi";
	if ($all != $maxi) {
		print "\b" for (1..len($maxi));
		print "\b\b\b";
		print "\b" for (1..len($all));
	} else {
		print "\n";
	}
}

sub web_crawler {
	my ($href) = @_;
	return sub {
		my $content = $_[0];
		print_next();
		$used{$href} = $_[1]->{"content-length"};
		add_into_res($href, $_[1]->{"content-length"});
		my $file;
		open($file, ">", "site.html");
		print $file $content;
		close($file);
		my @result;
		my $p = HTML::Parser->new(
			api_version => 3,
			start_h => [
				sub {
					my ($tagname, $attr) = @_;
					if ($tagname eq "a" and exists($attr->{"href"})) {
						my $a_href = $attr->{"href"};
						$a_href = check_and_add($href, $a_href);
						if (defined $a_href and (scalar(keys(%used)) < $maxi)) {
							if ($all == $maxi) {
								$cv->send();
								return;
							}
							$used{$a_href} = 0;
							push(@result, $a_href);
						}
					}
				}, "tagname, attr"],
			default_h => [sub {}, ""],
		);
		$p->parse_file("site.html");
		for my $i (@result) {
			$cv->begin;
			my $callback = web_crawler($i);
			http_get($i, $callback);
		}
		$cv->end;
	}
}

my $first_func = web_crawler($host);
$cv->begin;
http_get($host, $first_func);
$cv->recv();
for my $i (0..9) {
	print ($i + 1)."\n";
	print "\tName: $top10_host[$i] \n\tSize: $top10_val[$i]\n";
}
#my $file;
#open($file, ">", $filename);
#for my $i (keys %used) {
	#print $file $i." ".$used{$i}."\n";
#}
#close($file);
