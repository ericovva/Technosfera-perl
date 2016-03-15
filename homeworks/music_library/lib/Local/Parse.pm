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
our @EXPORT = qw(parse $SORT $COLUMNS);
our $SORT = '';
our $COLUMNS = '';
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
		$newstr =~/\.\/(.+)\/(\d+)\s\-\s(.+)\/(.+)\.(.+)/;
		#$1 = группа
		#$2 = год
		#$3 = альбом
		#$4 = трек
		#$5 = формат
		my $year = $2;
		$year = 0 + $year;
		#print $1."\n".$year."\n".$3."\n".$4."\n".$5."\n";
		my %newhash = (
			"band" => $1,
			"year" => $2,
			"album" => $3,
			"track" => $4,
			"format" => $5,
		);
		my $BAND_ = (!$BAND) ? $1 : $BAND;
		my $YEAR_ = (!$YEAR) ? $2 : $YEAR;
		my $ALBUM_ = (!$ALBUM) ? $3 : $ALBUM;
		my $TRACK_ = (!$TRACK) ? $4 : $TRACK;
		my $FORMAT_ = (!$FORMAT) ? $5 : $FORMAT;
		if ($newhash{"band"} eq $BAND_ and $newhash{"year"} == $YEAR_ 
			and $newhash{"album"} eq $ALBUM_ and $newhash{"track"} eq $TRACK_
			and $newhash{"format"} eq $FORMAT_) {
			$list{$cnt} = \%newhash;
			$cnt++;
		}
	}
	return \%list;
}
1;
