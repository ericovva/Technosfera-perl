package Local::Iterator::Filter;

use strict;
use warnings;
use base 'Local::Iterator';
				
sub next {
	my ($self) = @_;
	if ($self->{"end"}) {
		return (undef, 1);
	} else {
		my ($next, $end) = $self->{"iterator"}->next();
		if ($end) {
			$self->{"end"} = 1;
			return (undef, 1);
		} else {
			if ($self->{"callback"}->($next)) {
				return ($next, 0);
			} else {
				return (undef, undef);
			}
		}
	}
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

