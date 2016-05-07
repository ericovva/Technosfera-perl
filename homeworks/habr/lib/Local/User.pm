package Local::User;

use strict;
use warnings;
use HTML::Parser;
use FindBin;
use lib "$FindBin::Bin/../";
use base "Local::Request";

sub init {
	my ($self) = @_;
	if (exists $self->{"user"}) {
		my $parse = HTML::Parser-new(
			api_version => 3,
			start_h => [
				sub {
					my $obj = $self;
					return {
						my ($tag, $attr, $attrseq, $origntext) = @_;
						if ($tag eq "div" and exists($attr->{"class"}) and $attr->{"class"} eq "voting-wjt__counter-score js-karma_num") {
							$obj->{"is_karma"} = 1;
						}
					};
				}, "tagname, attr"],
			text_h => [
				sub {
					my $obj= $self;
					return {
						my ($text) = @_;
						if ($obj->{"is_karma"}) {
							$obj->{"karma"} = $text;
							$obj->{"is_karma"} = 0;
						}
						if ($obj->{"is_rank"}) {
							$obj->{"rank"} = $text;
							$obj->{"is_rank"} = 0;
						}
					}
				}, "text"],
			default_h => [sub {}, ""],
		);
	} else {
		
	}
};

=encoding utf8

=head1 NAME

Local::User
Local::User->new("user"=>"house2008");
Local::User->new("post"=> 283106);

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

1;
