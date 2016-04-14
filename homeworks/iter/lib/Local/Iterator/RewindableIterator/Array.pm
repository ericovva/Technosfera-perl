package Local::Iterator::RewindableIterator::Array;

use strict;
use warnings;	
use DDP;
use base 'Local::Iterator::RewindableIterator';

sub next {
	my ($self) = @_;
	if ($self->{"cur"} >= $self->{"length"}) {
		$self->{"end"} = 1;
		return (undef, 1);
	} else {
		$self->{"cur"}++;
		return ($self->{"array"} -> [$self->{"cur"} - 1], 0);
	}
}

=encoding utf8

=head1 NAME

Local::Iterator::Array - array-based iterator

=head1 SYNOPSIS

    my $iterator = Local::Iterator::Array->new(array => [1, 2, 3]);

=cut

1;
