package Local::Iterator::File;

use strict;
use warnings;
use DDP;

sub new {
	my ($class, %param) = @_;
	if (exists($param{"filename"})) {
		#filename
		my $fh;
		my $filename = $param{"filename"};
		open($fh, "<", $filename);
		$param{"fh"} = $fh;
		return bless \%param, $class;
	} else {
		#file handler
		#$param{"fh"} уже записан
		return bless \%param, $class
	}
}

sub next {
	my ($self) = @_;
	if ($self->{"end"}) {
		return (undef, 1);
	} else {
		my $fh = $self->{"fh"};
		my $line = <$fh>;
		chomp($line);
		if (eof) {
			$self->{"end"} = 1;
		}
		return ($line, 0);
	}
}

sub all {
	my ($self) = @_;
	my $ret = [];
	my $size = -1;
	my ($next, $end) = Local::Iterator::File::next($self);
	while (!$self->{"end"}) {
		$size++;
		$ret->[$size] = $next;
		($next, $end) = Local::Iterator::File::next($self);
	}
	$size++;
	$ret->[$size] = $next;
	return $ret;
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
