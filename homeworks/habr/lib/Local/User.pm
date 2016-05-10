package Local::User;

use strict;
use warnings;
use HTML::Parser;
use FindBin;
use Cache::Memcached;
use JSON::XS;
use XML::Dumper;
use lib "$FindBin::Bin/../";
use base "Local::Request";
use DDP;

sub init {
	my ($self) = @_;
	$self->{"again"} = 0;
	$self->{"cache"} = Cache::Memcached->new(
		servers => [$self->{"config"}->param("memcached.server")]
	);
	if (exists $self->{"nickname"}) {
		$self->{"url"} = "https://habrahabr.ru/users/".$self->{"nickname"}."/";
	} else {
		$self->{"url"} = "https://habrahabr.ru/post/".$self->{"post_id"}."/";
	}
};
sub get_from_habr {
	my ($self) = @_;
	if (exists $self->{"nickname"}) {
		$self->{"data"}->[0]->{"nickname"} = $self->{"nickname"};
		if ($self->{"again"}) {
			$self->{"url"} = "https://habrahabr.ru/users/".$self->{"nickname"}."/";
		}
		$self->get_html($self->{"config"}->param("filename.for_user"));
		my $parse = HTML::Parser->new(
			api_version => 3,
			start_h => [
				sub {
					my ($tag, $attr, $attrseq, $origntext) = @_;
					if ($tag eq "div" and exists($attr->{"class"}) and $attr->{"class"} eq "voting-wjt__counter-score js-karma_num") {
						$self->{"is_karma"} = 1;
					}
					if ($tag eq "div" and exists($attr->{"class"}) and $attr->{"class"} eq "statistic__value statistic__value_magenta") {
						$self->{"is_rank"} = 1;
					}
				}, "tagname, attr"],
			text_h => [
				sub {
					my ($text) = @_;
					$text =~ s/,/./;
					$text =~ s/–/-/;
					if ($self->{"is_karma"}) {
						$self->{"data"}->[0]->{"karma"} = $text;
						$self->{"is_karma"} = 0;
					}
					if ($self->{"is_rank"}) {
						$self->{"data"}->[0]->{"rank"} = $text;
						$self->{"is_rank"} = 0;
					}
				}, "text"],
			default_h => [sub {}, ""],
		);
		$parse->parse_file($self->{"config"}->param("filename.for_user"));
		if (exists($self->{"data"}->[0]->{"rank"})) {
			return 1;
		} else {
			$self->{"error"} = "Ошибка во время запроса данных о пользователе: ".$self->{"nickname"};
			return 0;
		}
	} else {
		$self->get_html($self->{"config"}->param("filename.for_user"));
		my $parse = HTML::Parser->new(
			api_version => 3,
			start_h => [
				sub {
					my ($tag, $attr) = @_;
					if (!$self->{"again"}) {
						if ($tag eq "a" and exists($attr->{"class"}) and $attr->{"class"} eq "author-info__nickname") {
							$self->{"is_user"} = 1;
						}
					} else {
						if ($tag eq "a" and exists($attr->{"class"}) and $attr->{"class"} eq "post-type__value post-type__value_author") {
							$self->{"is_user"} = 1;
						}
					}
				}, "tag, attr"],
			text_h => [
				sub {
					my ($text) = @_;
					$text =~ s/@//;
					if ($self->{"is_user"}) {
						$self->{"nickname"} = $text;
						$self->{"is_user"} = 0;
					}
				}, "text"],
			default_h => [sub {}, ""],
		);
		$parse->parse_file($self->{"config"}->param("filename.for_user"));
		if (exists($self->{"nickname"})) {
			return 1;
		} elsif (!$self->{"again"}) {
			$self->{"again"} = 1;
			return $self->get_from_habr();
		} else {
			$self->{"error"} = "Ошибка во время запроса данных о пользователе: ".$self->{"nickname"};
			return 0;
		}
	}
}
sub get_info {
	my ($self) = @_;
	if (exists $self->{"nickname"}) {
		if (!$self->{"refresh"}) {
			my $from_cache = $self->{"cache"}->get($self->{"nickname"});
			if (defined $from_cache) {
				my ($karma, $rank) = split('#', $from_cache);
				$self->{"data"}->[0]->{"nickname"} = $self->{"nickname"};
				$self->{"data"}->[0]->{"karma"} = $karma;
				$self->{"data"}->[0]->{"rank"} = $rank;
				return;
			}
		}
		$self->{"query"} = "select nickname, karma, rank from users where nickname=\"".$self->{"nickname"}."\"";
	} else {
		if ($self->get_from_habr()) {
			$self->get_info();
			return;
		} else {
			return;
		}
	}
	my $info = undef;
	$info = $self->send() if !$self->{"refresh"};
	if (defined $info) {
		$self->{"data"}->[0] = $info;
		return $info;
	} elsif (!$self->{"refresh"}) {
		if ($self->get_from_habr()) {
			$self->{"cache"}->set($self->{"nickname"}, $self->{"data"}->[0]->{"karma"}."#".$self->{"data"}->[0]->{"rank"}, 60 * 60 * 2);
			$self->{"query"} = "insert into users (nickname, karma, rank) values (\"".$self->{"nickname"}."\",".$self->{"data"}->[0]->{"karma"}.",".$self->{"data"}->[0]->{"rank"}.")";
		} else {
			return;
		}
	} else {
		if ($self->get_from_habr()) {
			$self->{"cache"}->set($self->{"nickname"}, $self->{"data"}->[0]->{"karma"}."#".$self->{"data"}->[0]->{"rank"}, 60 * 60 * 2);
			$self->{"query"} = "update users set karma=".$self->{"data"}->[0]->{"karma"}.",rank=".$self->{"data"}->[0]->{"rank"}." where nickname=\"".$self->{"nickname"}."\"";
		} else {
			return;
		}
	}
	$self->send();
}


1;
