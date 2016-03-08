use Data::Dumper;
#$text = "perl is the subject on page 493 of the book.";
#$text =~ s/[^A-Za-z\s]+/500/;
#print $text;
#e([\+|-]\d+\.?\d+) * 10 ** $2
$a = <>;
$a =~s/(\d*\.?\d+)e([\+|-]?\d*\.?\d+)/[$1 * 10 ** $2]/g;
print $a;
