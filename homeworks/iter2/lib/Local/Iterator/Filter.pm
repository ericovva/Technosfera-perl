package Local::Iterator::Filter;

use strict;
use warnings;
use base 'Local::Iterator';
				
sub next {
	my ($self) = @_;
	if ($self->{"iterator"}{"end"}) {
		return (undef, 1);
	} else {
		my ($next, $end) = $self->{"iterator"}->next();
		if ($end) {
			$self->{"end"} = 1;
			return (undef, 1);
		} else {
			if ($self->{"callback"}->($next)) {
				$self->{"end"} = 0;
				return ($next, 0);
			} else {
				$self->{"end"} = 0;
				return (undef, undef);
			}
		}
	}
}

sub init {
	my ($self) = @_;
}

=encoding utf8

=head1 NAME

Local::Iterator::Map

=head1 SYNOPSIS

    my $iterator = Local::Iterator::Filter->new(
		iterator => $another_iterator,
	);
	$iterator->filter(
		sub { ... }
	);

=cut

1;

