package Local::Iterator;

use DDP;
use strict;
use warnings;

sub showMe {
	my ($self) = @_;
	p $self;
}

sub new {
	my ($class, %params) = @_;
	$params{"cur"} = 0;
	$params{"end"} = 0;
	$params{"_end"} = 0;
	$params{"length"} = 0;
	if ($class eq "Local::Iterator::RewindableIterator::File") {
		$params{"name"} = "File";
		if (exists($params{"filename"})) {
			#filename
			my $fh;
			my $filename = $params{"filename"};
			open($fh, "<", $filename);
			$params{"fh"} = $fh;
			$params{"end"} = 0;
			$params{"_end"} = 0;
			return bless \%params, $class;
		}
	} elsif ($class eq "Local::Iterator::RewindableIterator::Array") {
		$params{"name"} = "Array";
		$params{"length"} = scalar(@{$params{"array"}});
	} elsif ($class eq "Local::Iterator::RewindableIterator::Concater") {
		$params{"name"} = "Concater";
		$params{"length"} = scalar(@{$params{"iterators"}});
	} elsif ($class eq "Local::Iterator::Aggregator") {
		$params{"name"} = "Aggregator";
	} elsif ($class eq "Local::Iterator::Map") {
		$params{"name"} = "Map";
	}
	
	return bless \%params, $class;
}

sub all {
	my ($self) = @_;
	my $ret = [];
	my $size = -1;
	my ($next, $end) = $self->next($self);
	while (!$self->{"end"}) {
		if (defined $end) {
			$size++;
			$ret->[$size] = $next;
		}
		($next, $end) = $self->next($self);
	}
	return $ret;
}

=encoding utf8

=head1 NAME

Local::Iterator - base abstract iterator

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

1;
