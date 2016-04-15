package Local::Iterator::Rewindable::Interval;

use strict;
use warnings;
use DateTime;
use DDP;
use Local::Interval;
use base 'Local::Rewindable';

sub init {
	my ($self) = @_;
	$self->{"cur"} = $self->{"from"};
	$self->{"end"} = 0;
	$self->{"length"} = $self->{"step"} if !exists($self->{"length"});
}

sub next {
	my ($self) = @_;
	if ($self->{"end"}) {
		return (undef, 1);
	}
	my $res = $self->{"cur"};
	$res += $self->{"length"};
	if ($res > $self->{"to"}) {
		$self->{"end"} = 1;
		return (undef, 1);
	} else {
		$res = Local::Interval->new(
			from => $self->{"cur"},
			to => $res,
		);
		$self->{"cur"} += $self->{"step"};
		if ($self->{"cur"} > $self->{"to"}) {
			$self->{"end"} = 1;
			return (undef, 1);
		}
		return ($res, 0);
	}
}

sub goToBegin {
	my ($self) = @_;
	$self->{"end"} = 0;
	$self->{"cur"} = $self->{"from"};
}

=encoding utf8

=head1 NAME

Local::Iterator::Interval - interval iterator

=head1 SYNOPSIS

    use DateTime;
    use DateTime::Duration;

    my $iterator = Local::Iterator::Interval->new(
      from   => DateTime->new('...'),
      to     => DateTime->new('...'),
      step   => DateTime::Duration->new(seconds => 25),
      length => DateTime::Duration->new(seconds => 35),
    );

=cut

1;
