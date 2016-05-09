#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use DDP;
use lib "$FindBin::Bin/../lib";
use Local::User;
use Local::Post;
use Local::Commenters;
use Cache::Memcached;
use Getopt::Long;
use JSON::XS;
my $format;
my $refresh;
my $p;

if ($ARGV[0] eq "user") {
	my $name;
	my $post_id;
	GetOptions("name=s" => \$name, "post=i", \$post_id, "format=s" => \$format, "refresh" => \$refresh);
	if (not defined $refresh) {
		$refresh = 0;
	}
	if (defined $name) {
		$p = Local::User->new("nickname" => $name, "refresh" => $refresh);
	} else {
		$p = Local::User->new("post_id" => $post_id, "refresh" => $refresh);
	}
	$p->get_info();
} elsif ($ARGV[0] eq "post") {
	my $post_id;
	GetOptions("id=i" => \$post_id, "format=s" => \$format, "refresh" => \$refresh);
	if (not defined $refresh) {
		$refresh = 0;
	}
	$p = Local::Post->new("post_id" => $post_id, "refresh" => $refresh);
	$p->get_info();
} elsif ($ARGV[0] eq "commenters") {
	my $post_id;
	GetOptions("post=i" => \$post_id, "refresh" => \$refresh, "format=s" => \$format);
	if (not defined $refresh) {
		$refresh = 0;
	}
	$p = Local::Commenters->new("post_id" => $post_id, "refresh" => $refresh);
	$p->get_info();
} elsif ($ARGV[0] eq "self_commentors") {
	GetOptions("refresh" => \$refresh, "format=s" => \$format);
	if (not defined $refresh) {
		$refresh = 0;
	}
	$p = Local::Request->new(
		"query" => "select author from posts where author_comment = 1"
	);
	my @result;
	my $sth = $p->send(1);
	while (my $author = $sth->fetchrow_arrayref()) {
		my $user = Local::User->new("nickname" => $author->[0], "refresh" => $refresh);
		$user->get_info();
		my $error = $user->getError();
		if (defined $error) {
			warn $error;
		} else {
			push(@result, $user->getData());
		}
	}
	$p->setData(\@result);
} elsif ($ARGV[0] eq "desert_posts") {
	my $n;
	GetOptions("n=i" => \$n, "format=s" => \$format, "refresh" => \$refresh);
	if (not defined $refresh) {
		$refresh = 0;
	}
	$p = Local::Request->new(
		"query" => "select id from posts where amount_commenters < $n"
	);
	my $sth = $p->send(1);
	my @result;
	while (my $id = $sth->fetchrow_arrayref()) {
		my $post = Local::Post->new("post_id" => $id->[0], "refresh" => $refresh);
		$post->get_info();
		my $error = $post->getError();
		if (defined $error) {
			warn $error;
		} else {
			push(@result, $post->getData());
		}
	}
	$p->setData(\@result);
}
if (defined $p) {
	if (defined $format) {
		if ($format eq "json") {
			p $p->json();
		} elsif ($format eq "xml") {
			$p->xml($p->config("filename.for_xml"));
		}
	} else {
		die "Нет формата входных данных \n";
	}
} else {
	die "Неправильные ключи в командной строке \n";
}
