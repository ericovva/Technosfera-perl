package Local::Iterator::Concater;

use strict;
use warnings;
use DDP;
use base 'Local::RewindableIterator';


sub next {
	my ($self) = @_;
	if ($self->{"end"}) {
		return (undef, 1);
	} else {
		my ($next, $end) = $self->{"iterators"}->[$self->{"cur"}]->next();
		if ($end) {
			if ($self->{"cur"} + 1 == $self->{"length"}) {
				$self->{"end"} = 1;
				return (undef, 1);
			} else {
				$self->{"cur"}++;
				($next, $end) = $self->{"iterators"}->[$self->{"cur"}]->next();
				return ($next, 0);
			}
		} else {
			return ($next, 0);
		}
	}
}


=encoding utf8

=head1 NAME

Local::Iterator::Concater - concater of other iterators

=head1 SYNOPSIS

    my $iterator = Local::Iterator::Concater->new(
        iterators => [
            $another_iterator1,
            $another_iterator2,
        ],
    );

=cut

1;
