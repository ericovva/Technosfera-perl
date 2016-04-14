package Local::Iterator::Filter;

use strict;
use warnings;

sub new {
	my ($class, %params) = @_;
	return bless \%params, $class;
}

sub filter {
	my ($self, $callback) = @_;
	my $size = -1;
	my $ret = [];
	my ($next, $end) = $self->{"iterator"}->next();
	while (!$self->{"iterator"}{"end"}) {
		if ($callback->($next)) {
			$size++;
			$ret->[$size] = $next;
		}
		($next, $end) = $self->{"iterator"}->next();
	}
	return $ret;
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

