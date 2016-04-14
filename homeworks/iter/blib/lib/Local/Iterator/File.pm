package Local::Iterator::File;

use strict;
use warnings;
use DDP;

BEGIN {
	use base 'Local::Iterator';
}

sub new {
	my ($class, %param) = @_;
	if (exists($param{"filename"})) {
		#filename
		my $fh;
		my $filename = $param{"filename"};
		open($fh, "<", $filename);
		$param{"fh"} = $fh;
		$param{"end"} = 0;
		$param{"_end"} = 0;
		return bless \%param, $class;
	} else {
		#file handler
		#$param{"fh"} уже записан
		return bless \%param, $class
	}
}

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

sub goToBegin {
	my ($self) = @_;
	my $fh = $self->{"fh"};
	seek($fh, 0, 0);
	$self->{"fh"} = $fh;
	$self->{"end"} = 0;
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
