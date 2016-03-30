use strict;
use warnings;
use DDP;
sub func {
	my $limit = shift;
	my $send = (pack("s", $limit));
	print $send;
};
func(114);
