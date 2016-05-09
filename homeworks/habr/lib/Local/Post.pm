package Local::Post;

use strict;
use warnings;
use HTML::Parser;
use FindBin;
use JSON::XS;
use XML::Dumper;
use lib "$FindBin::Bin/../";
use base "Local::Request";
use DDP;

sub init {
	my ($self) = @_;
	$self->{"again"} = 0;
	$self->{"can_parse_rank"} = 1;
	$self->{"url"} = "https://habrahabr.ru/post/".$self->{"post_id"}."/";
}

sub get_from_habr {
	my ($self) = @_;
	$self->{"data"}->[0]->{"post_id"} = $self->{"post_id"};
	$self->get_html("post.html") if !$self->{"again"};
	my $parser = HTML::Parser->new(
		api_version => 3,
		start_h => [
			sub {
				my ($tag, $attr) = @_;
				if (!$self->{"again"}) {
					if ($tag eq "a" and exists($attr->{"class"}) and $attr->{"class"} eq "author-info__nickname") {
						$self->{"is_author"} = 1;
					}
				} else {
					if ($tag eq "a" and exists($attr->{"class"}) and $attr->{"class"} eq "post-type__value post-type__value_author") {
						$self->{"is_author"} = 1;
					}
				}
				if ($tag eq "title") {
					$self->{"is_theme"} = 1;
				}
				if ($tag eq "span" and exists($attr->{"class"}) and $attr->{"class"} eq "voting-wjt__result-score js-score") {
					$self->{"can_parse_rank"} = 0;
					$self->{"data"}->[0]->{"rank"} = 0;
				}
				if ($tag eq "span" and exists($attr->{"class"}) and $attr->{"class"} eq "voting-wjt__counter-score js-score" and $self->{"can_parse_rank"}) {
					$self->{"is_rank"} = 1;
					$self->{"can_parse_rank"} = 0;
				}
				if ($tag eq "div" and exists($attr->{"class"}) and $attr->{"class"} eq "views-count_post") {
					$self->{"is_views"} = 1;
				}
				if ($tag eq "span" and exists($attr->{"class"}) and $attr->{"class"} eq "favorite-wjt__counter js-favs_count") {
					$self->{"is_stars"} = 1;
				}
			}, "tagname, attr"],
		text_h => [
			sub {
				my ($text) = @_;
				if ($self->{"is_author"}) {
					$text =~ s/@//;
					$self->{"data"}->[0]->{"author"} = $text;
					$self->{"is_author"} = 0;
				} elsif ($self->{"is_theme"}) {
					($text) = ($text =~ m/(.*?)\s\//);
					$self->{"data"}->[0]->{"theme"} = $text;
					$self->{"is_theme"} = 0;
				} elsif ($self->{"is_rank"}) {
					$text =~ s/–/-/;
					$self->{"data"}->[0]->{"rank"} = $text;
					$self->{"is_rank"} = 0;
				} elsif ($self->{"is_views"}) {
					if ($text =~ /k/) {
						my ($big, $little) = ($text =~ m/(\d+),?(\d*)k/);
						$little = 0 if $little eq "";
						$big *= 10; $big += $little; $big *= 100;
						$text = $big;
						$self->{"data"}->[0]->{"views"} = $text;
					} else {
						$self->{"data"}->[0]->{"views"} = $text;
					}
					$self->{"is_views"} = 0;
				} elsif ($self->{"is_stars"}) {
					$self->{"data"}->[0]->{"stars"} = $text;
					$self->{"is_stars"} = 0;
				}
				
			}, "text"],
		default_h => [sub {}, ""],
	);
	$parser->parse_file("post.html");
	if (exists($self->{"data"}->[0]->{"author"})) {
		return 1;
	} elsif (!$self->{"again"}) {
		$self->{"again"} = 1;
		return $self->get_from_habr();
	} else {
		$self->{"error"} = "Ошибка во время запроса данных о статье ".$self->{"post_id"};
		return 0;
	}
}

sub get_info {
	my ($self) = @_;
	$self->{"query"} = "select author, theme, rank, views, stars from posts where id=".$self->{"post_id"};
	my $info = undef;
	$info = $self->send();
	if (defined $info) {
		if (!$self->{"refresh"}) {
			$self->{"data"}->[0] = $info;
			return;
		} else {
			if (!$self->get_from_habr()) {
				return;
			}
			$self->{"query"} = "update posts set theme=\"".$self->{"data"}->[0]->{"theme"}."\", rank=".$self->{"data"}->[0]->{"rank"}.", views=".$self->{"data"}->[0]->{"views"}.", stars=".$self->{"data"}->[0]->{"stars"}." where id=".$self->{"post_id"};
		}
	} else {
		if (!$self->get_from_habr()) {
			return;
		}
		$self->{"query"} = "insert into posts (id, author, theme, rank, views, stars) values (".
		$self->{"data"}->[0]->{"post_id"}.",\"".$self->{"data"}->[0]->{"author"}."\",\"".$self->{"data"}->[0]->{"theme"}."\",".$self->{"data"}->[0]->{"rank"}.",".$self->{"data"}->[0]->{"views"}.",".$self->{"data"}->[0]->{"stars"}.")";
	}
	$self->send();
}

1;
