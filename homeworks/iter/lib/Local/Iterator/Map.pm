package Local::Iterator::Map;

use strict;
use warnings;
use base 'Local::Iterator';

sub next {
	my ($self) = @_;
	my ($next, $end) = $self->{"iterator"}->next();
	if ($end) {
		$self->{"end"} = 1;
		return (undef, 1);
	}
	$self->{"end"} = 0;
	return ($self->{"callback"}->($next), 0);
}

=encoding utf8

=head1 NAME

Local::Iterator::Map

=head1 SYNOPSIS

    my $iterator = Local::Iterator::Map->new(
		iterator => $another_iterator,
	);
	$iterator->map(
		sub { ... }
	);

=cut

1;
