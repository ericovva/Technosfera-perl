=head
	Модуль, который получает на вход строку, а возвращает
	hash вида
	{
		0: {
			"band" => " ",
			"year" => " ",
			"album" => " ",
			"track" => " ",
			"format" => " ",
		},
		1: {
			"band" => " ",
			"year" => " ",
			"album" => " ",
			"track" => " ",
			"format" => " ",
		},
		...
	}
=cut
package Local::Parse;
use Getopt::Long;
use strict;
no strict 'refs';
use warnings;
use Exporter 'import';
our @EXPORT = qw(parse get_SORT get_COLUMNS);
my $sortFromKey = '';
my $columnsFromKey = '';
my %keysRun = (
	band => '',
	year => 0,
	album => '',
	track => '',
	format => '',
);

sub get_SORT {
	return $keysRun{"sort"};
}
sub get_COLUMNS {
	return $keysRun{"columns"};
}

GetOptions("band=s" => \$keysRun{"band"}, "year=s" => \$keysRun{"year"}, "album=s" => \$keysRun{"album"}, 
	"track=s" => \$keysRun{"track"}, "format=s" => \$keysRun{"format"}, 
	"sort=s" => \$keysRun{"sort"}, "columns=s" => \$keysRun{"columns"});
	
sub parse {
	my $string;
	my $newstr;
	my %list = ();
	my $cnt = 0;
	if ($keysRun{"year"}) {
		$keysRun{"year"} = int($keysRun{"year"});
	}
	while ($newstr = <>) {
		chomp($newstr);
		my @match = my ($band, $year, $album, $track, $format) = ($newstr =~/^\.\/(.+)\/(\d+)\s\-\s(.+)\/(.+)\.+(.+)$/);
		$year = int($year);
		my %newhash = (
			"band" => $band,
			"year" => $year,
			"album" => $album,
			"track" => $track,
			"format" => $format,
		);
		my $toAdd = 1;
		foreach my $i (keys %newhash) {
			if ($keysRun{"$i"}) {
				if ($i ne "year") {
					if ($newhash{$i} ne $keysRun{$i}) {
						$toAdd = 0;
						last;
					}
				} else {
					if ($newhash{$i} != $keysRun{$i}) {
						$toAdd = 0;
						last;
					}
				}
			}
		}
		if ($toAdd) {
			$list{$cnt} = \%newhash;
			$cnt++;
		}
	}
	return \%list;
}
1;
