package Local::Iterator::RewindableIterator::File;

use strict;
use warnings;
use DDP;
use base 'Local::Iterator::RewindableIterator';

sub next {
	my ($self) = @_;
	if ($self->{"_end"}) {
		$self->{"end"} = 1;
	}
	if ($self->{"end"}) {
		return (undef, 1);
	} else {
		my $fh = $self->{"fh"};
		my $line = <$fh>;
		chomp($line);
		if (eof) {
			$self->{"_end"} = 1;
		}
		return ($line, 0);
	}
}

=encoding utf8

=head1 NAME

Local::Iterator::File - file-based iterator

=head1 SYNOPSIS

    my $iterator1 = Local::Iterator::File->new(filename => '/tmp/file');

    open(my $fh, '<', '/tmp/file2');
    my $iterator2 = Local::Iterator::File->new(fh => $fh);

=cut

1;
