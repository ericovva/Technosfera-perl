package Local::Iterator::Aggregator;

use lib '/home/gmoryes/Technosfera-perl/homeworks/iter/lib';
use strict;
no strict "refs";
use warnings;
use DDP;

sub new {
		my ($class, %params) = @_;
		$params{"end"} = 0;
		return bless \%params, $class;
}

sub next {
	my ($self) = @_;
	my $ret = [];
	my $i;
	for ($i = 0; $i < $self->{"chunk_length"}; $i++) {
		my ($next, $end) = $self->{"iterator"}->next();
		if ($end) {
			last;
		} else {
			$ret->[$i] = $next;
		}
	}
	if ($i != 0) {
		return ($ret, 0);
	} else {
		$self->{"end"} = 1;
		return (undef, 1);
	}
}

sub all {
	my ($self) = @_;
	my $res = [];
	my $size = -1;
	my ($next, $end) = Local::Iterator::Aggregator::next($self);
	while (!$self->{"end"}) {
		$size++;
		$res->[$size] = $next;
		($next, $end) = Local::Iterator::Aggregator::next($self);
	}
	return $res;
}

=encoding utf8

=head1 NAME

Local::Iterator::Aggregator - aggregator of iterator

=head1 SYNOPSIS

    my $iterator = Local::Iterator::Aggregator->new(
        chunk_length => 2,
        iterator => $another_iterator,
    );

=cut

1;
