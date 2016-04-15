package Local::Iterator::Mixer;

use strict;
use warnings;
use base 'Local::Iterator';

sub init {
	my ($self) = @_;
	$self->{"length"} = scalar(@{$self->{"iterators"}});
}

sub next {
	my ($self) = @_;
	return (undef, 1) if $self->{"end"};
	my $old = $self->{"cur"};
	my ($next, $end) = $self->{"iterators"}[$self->{"cur"}]->next();
	while ($end) {
		$self->{"cur"}++;
		$self->{"cur"} %= $self->{"length"};
		if ($self->{"cur"} == $old) {
			$self->{"end"} = 1;
			return (undef, 1);
		}
		($next, $end) = $self->{"iterators"}[$self->{"cur"}]->next();
	}
	$self->{"cur"} = ($self->{"cur"} + 1) % $self->{"length"};
	return ($next, 0); 
}

1;
