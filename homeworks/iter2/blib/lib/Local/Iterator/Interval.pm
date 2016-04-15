package Local::Iterator::Interval;

use strict;
use warnings;
use DateTime;
use DDP;
use Local::Interval;

sub new {
	my ($class, %params) = @_;
	$params{"cur"} = $params{"from"};
	$params{"end"} = 0;
	$params{"length"} = $params{"step"} if !exists($params{"length"});
	return bless \%params, $class;
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
