package Local::Interval;

use strict;
use warnings;

sub new {
	my ($class, %params) = @_;
	return bless \%params, $class;
}

sub from {
	my ($self) = @_;
	return $self->{"from"};
}

sub to {
	my ($self) = @_;
	return $self->{"to"};
}

=encoding utf8

=head1 NAME

Local::Interval - time interval

=head1 SYNOPSIS

    my $interval = Local::Interval->new('...');

    $interval->from(); # DateTime
    $interval->to(); # DateTime

=cut

1;

