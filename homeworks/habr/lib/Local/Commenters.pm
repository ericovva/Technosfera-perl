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
						$self->{"used"}{$text} = 1;
						my $p = Local::User->new("nickname" => $text, "refresh" => $self->{"refresh"});
						$p->get_info();
						if (exists($p->{"error"})) {
							warn $p->{"error"};
						} else {
							push(@{$self->{"data"}}, $p->{"data"}->[0]);
						}
					}
					$self->{"is_comment_user"} = 0;
				}
			}, "text"],
		default_h => [sub {}, ""],
	);
	$self->get_html("commenters.html");
	$parser->parse_file("commenters.html");
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
		if ($self->{"refresh"}) {
			if (!$self->get_from_habr()) {
				return;
			}
			my @users;
			for my $i (keys $self->{"used"}) {
				push(@users, $i);
				if ($i eq $info->{"author"}) {
					$self->{"author_comment"} = 1;
				}
			}
			$self->{"query"} = "update posts set commenters=\"".join(',', @users)."\", author_comment=".$self->{"author_comment"}.", amount_commenters=".scalar(@users)." where id=".$info->{"id"};
		} else {
			if (defined($info->{"commenters"})) {
				my @users = split(',', $info->{"commenters"});
				for my $i (@users) {
					my $p = Local::User->new("nickname" => $i, "refresh" => $self->{"refresh"});
					$p->get_info();
					if (exists($p->{"error"})) {
						warn $p->{"error"};
					} else {
						push (@{$self->{"data"}}, $p->{"data"}->[0]);
					}
				}
				#return $self->{"data"};
			} else {
				if (!$self->get_from_habr()) {
					return;
				}
				my @users;
				for my $i (keys $self->{"used"}) {
					push(@users, $i);
				}
				$self->{"query"} = "update posts set commenters=\"".join(',', @users)."\", author_comment=".$self->{"author_comment"}.", amount_commenters=".scalar(@users)." where id=".$info->{"id"};
			}
		}
	} else {
		my $p = Local::Post->new("post_id" => $self->{"post_id"}, "refresh" => $self->{"refresh"});
		$p->get_info();
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
