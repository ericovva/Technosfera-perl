package Local::Iterator::Rewindable::Array;

use strict;
use warnings;	
use DDP;
use base 'Local::Iterator::Rewindable';

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

sub init {
	my ($self) = @_;
	$self->{"length"} = scalar(@{$self->{"array"}});
}

sub goToBegin {
	my ($self) = @_;
	$self->{"cur"} = 0;
	$self->{"end"} = 0;
}

=encoding utf8

=head1 NAME

Local::Iterator::Rewindable::Array - array-based iterator

=head1 SYNOPSIS

    my $iterator = Local::Iterator::Array->new(array => [1, 2, 3]);

=cut

1;
