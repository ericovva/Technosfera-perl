package Plugin;

use strict;
our %state = ();
sub parse {
	my $text = shift;
	my @text = split ('\.', $text);
	for my $i (@text) {
		if ($i =~ /,/) {
			my @words = split('\s+', $i);
			@words = grep((length($_) < 5) && ($_ ne ""), @words);
			for my $i (@words) {
				$state{$i}++;
			}
		}
	}
}
1;
