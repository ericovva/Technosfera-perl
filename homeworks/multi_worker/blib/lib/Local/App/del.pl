
use Fcntl ':flock';
use JSON::XS;
my $fh;
open($fh, '+<', "newfile.txt");
$prev = 0;
while ($line = <$fh>) {
	$cur = tell($fh);
	$line =~ /(\d+)\s\=/;
	if ($1 == 13) {
		seek($fh, $prev - $cur, 1);
		print $fh "abcd";
		exit;
	}
	$prev = $cur;
}
