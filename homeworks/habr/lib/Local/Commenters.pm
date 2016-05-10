package Local::Commenters;

use strict;
use warnings;
use HTML::Parser;
use FindBin;
use JSON::XS;
use XML::Dumper;
use lib "$FindBin::Bin/../";
use Local::Post;
use base "Local::Request";
use DDP;

sub init {
	my ($self) = @_;
	$self->{"author_comment"} = 0;
	$self->{"url"} = "https://habrahabr.ru/post/".$self->{"post_id"}."/";
}

sub get_from_habr {
	my ($self) = @_;
	my $parser = HTML::Parser->new(
		api_version => 3,
		start_h => [
			sub {
				my ($tag, $attr) = @_;
				if ($tag eq "a" and exists($attr->{"class"}) and $attr->{"class"} eq "comment-item__username") {
					$self->{"is_comment_user"} = 1;
				}
			}, "tagname, attr"],
		text_h => [
			sub {
				my ($text) = @_;
				if ($self->{"is_comment_user"}) {
					$text =~ s/@//;
					if (!$self->{"used"}{$text}) {
						#p $text;
						if ($text eq $self->{"author"}) {
							$self->{"author_comment"} = 1;
						}
						$self->{"used"}{$text} = 1;
						my $p = Local::User->new("nickname" => $text, "refresh" => $self->{"refresh"});
						$p->get_info();
						if (exists($p->{"error"})) {
							warn $p->{"error"};
						} else {
							push(@{$self->{"data"}}, $p->{"data"}->[0]);
							my $req = Local::Request->new("query" => "select * from commenters where nickname=\"".$p->{"nickname"}."\" and id=".$self->{"post_id"});
							my $ans = $req->send();
							if (!$ans) {
								$req->{"query"} = "insert into commenters (nickname, id) values (\"".$p->{"nickname"}."\",".$self->{"post_id"}.")";
								$req->send();
							}
						}
					}
					$self->{"is_comment_user"} = 0;
				}
			}, "text"],
		default_h => [sub {}, ""],
	);
	$self->get_html($self->{"config"}->param("filename.for_commenters"));
	$parser->parse_file($self->{"config"}->param("filename.for_commenters"));
	if (exists($self->{"data"})) {
		return 1;
	} else {
		$self->{"error"} = "Ошибка во время запроса данных о комментаторах статьи ".$self->{"post_id"};
		return 0;
	}
}

sub get_info {
	my ($self) = @_;
	$self->{"query"} = "select * from posts where id=".$self->{"post_id"};
	my $info = undef;
	$info = $self->send();
	if (defined($info->{"id"})) {
		$self->{"author"} = $info->{"author"};
		if ($self->{"refresh"}) {
			if (!$self->get_from_habr()) {
				return;
			}
			$self->{"query"} = "update posts set author_comment=".$self->{"author_comment"}." where id=".$info->{"id"};
		} else {
			$self->{"query"} = "select nickname from commenters where id=".$self->{"post_id"};
			my $sth = $self->send(1);
			my $ans = $sth->fetchrow_hashref();
			if ($ans) {
				while(1) {				
					my $p = Local::User->new("nickname" => $ans->{"nickname"}, "refresh" => $self->{"refresh"});
					$p->get_info();
					if (exists($p->{"error"})) {
						warn $p->{"error"};
					} else {
						push (@{$self->{"data"}}, $p->{"data"}->[0]);
					}
					last if !($ans = $sth->fetchrow_hashref());
				}
				return;
			} else {
				if (!$self->get_from_habr()) {
					return;
				}
				$self->{"query"} = "update posts set author_comment=".$self->{"author_comment"}." where id=".$info->{"id"};
			}
		}
	} else {
		my $p = Local::Post->new("post_id" => $self->{"post_id"}, "refresh" => $self->{"refresh"});
		$p->get_info();
		$self->{"author"} = $p->{"data"}->[0]->{"author"};
		if (exists($p->{"error"})) {
			$self->{"error"} = $p->{"error"};
		} else {
			$self->get_info();
		}
		return;
	}
	$self->send();
}

1;
