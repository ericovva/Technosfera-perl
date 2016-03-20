use JSON::XS;
use DDP;
 (JSON::XS->new->utf8->decode('{\n}'));
my @arr = ();
my @arr1 = (1,2,3);
my $str = "gmoryes\@gmail";
if ($str =~ m{^.+@.+$}x) {
	print "correct \n";
}
#$source =~ /("(?:[^"\\]|\\(?:["\\\/bfnrt]|(?:u\d{4})))+")/;
#print $1;
