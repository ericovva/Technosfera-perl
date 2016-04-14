package Local::Iterator;

use DDP;
use strict;
use warnings;

sub showMe {
	my ($self) = @_;
	p $self;
}

sub all {
	my ($self) = @_;
	my $ret = [];
	my $size = -1;
	my ($next, $end) = $self->next($self);
	while (!$self->{"end"}) {
		$size++;
		$ret->[$size] = $next;
		($next, $end) = $self->next($self);
	}
	return $ret;
}

=encoding utf8

=head1 NAME

Local::Iterator - base abstract iterator

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

1;
