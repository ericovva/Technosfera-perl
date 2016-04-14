package Local::Iterator::Map;

use strict;
use warnings;

sub new {
	my ($class, %params) = @_;
	return bless \%params, $class;
}

sub next {
	my ($self) = @_;
	return $self->{"iterator"}->next();
}

sub map {
	my ($self, $callback) = @_;
	my $ret = [];
	my $size = -1;
	my ($next, $end) = Local::Iterator::Map::next($self);
	while (!$self->{"iterator"}{"end"}) {
		$size++;
		$ret->[$size] = $callback->($next);
		($next, $end) = Local::Iterator::Map::next($self);
	}
	$self->{"iterator"}->goToBegin($self);
	return $ret;
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
