package Local::Iterator::Array;

use strict;
use warnings;
use DDP;

sub new {
	my ($class, %params) = @_;
	$params{"cur"} = 0;
	$params{"length"} = scalar(@{$params{"array"}});
	$params{"end"} = 0;
	return bless \%params, $class;
}

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

sub all {
	my ($self) = @_;
	my $ret = [];
	my $size = -1;
	my ($next, $end) = Local::Iterator::Array::next($self);
	while (!$self->{"end"}) {
		$size++;
		$ret->[$size] = $next;
		($next, $end) = Local::Iterator::Array::next($self);
	}
	return $ret;
}

=encoding utf8

=head1 NAME

Local::Iterator::Array - array-based iterator

=head1 SYNOPSIS

    my $iterator = Local::Iterator::Array->new(array => [1, 2, 3]);

=cut

1;
