=head
	Модуль, который получает на вход строку, а возвращает
	hash вида
	{
		"band" => " ",
		"year" => " ",
		"album" => " ",
		"track" => " ",
		"format" => " ",
	}
=cut
package Local::Parse;
use Getopt::Long;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw(parse get_SORT get_COLUMNS);
my $SORT = '';
my $COLUMNS = '';
sub get_SORT {
	#print "SORT::::: $SORT \n";
	return $SORT;
}
sub get_COLUMNS {
	return $COLUMNS;
}
sub parse {
	my $string;
	my $newstr;
	my %list = ();
	my $cnt = 0;
	my $BAND = '';
	my $YEAR = '';
	my $ALBUM = '';
	my $TRACK = '';
	my $FORMAT = '';
	GetOptions("band=s" => \$BAND, "year=s" => \$YEAR, "album=s" => \$ALBUM, 
				"track=s" => \$TRACK, "format=s" => \$FORMAT, "sort=s" => \$SORT, "columns=s" => \$COLUMNS);
	if ($YEAR) {
		$YEAR = 0 + $YEAR;
	}
	while ($newstr = <>) {
		chomp($newstr);
		my ($band, $year, $album, $track, $format) = ($newstr =~/\.\/(.+)\/(\d+)\s\-\s(.+)\/(.+)\.+(.+)/);
		#$1 = группа
		#$2 = год
		#$3 = альбом
		#$4 = трек
		#$5 = формат
		$year = 0 + $year;
		#print $1."\n".$year."\n".$3."\n".$4."\n".$5."\n";
		my %newhash = (
			"band" => $band,
			"year" => $year,
			"album" => $album,
			"track" => $track,
			"format" => $format,
		);
		my $BAND_ = (!$BAND) ? $band : $BAND;
		my $YEAR_ = (!$YEAR) ? $year : $YEAR;
		my $ALBUM_ = (!$ALBUM) ? $album : $ALBUM;
		my $TRACK_ = (!$TRACK) ? $track : $TRACK;
		my $FORMAT_ = (!$FORMAT) ? $format : $FORMAT;
		if ($band eq $BAND_ and $year == $YEAR_ 
			and $album eq $ALBUM_ and $track eq $TRACK_
			and $format eq $FORMAT_) {
			$list{$cnt} = \%newhash;
			$cnt++;
		}
	}
	return \%list;
}
1;
