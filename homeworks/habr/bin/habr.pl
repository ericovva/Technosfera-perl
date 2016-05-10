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
if ($ARGV[0] eq "create_db") {
	$p = Local::Request->new(
		"query" => "CREATE TABLE users (
			id integer primary key autoincrement, 
			nickname varchar(50), 
			karma float, 
			rank float
		)",
	);
	my $db;
	open($db, ">", $p->config("database.filename"));
	close($db);
	$db = $p->send(-1);
	$p = Local::Request->new(
		"query" => "CREATE TABLE posts (
			author varchar(50),
			theme text,
			rank float,
			views integer,
			stars integer,
			id integer,
			author_comment integer
		)",
	);
	$db += $p->send(-1);
	$p = Local::Request->new(
		"query" => "CREATE TABLE commenters (
			nickname varchar(50),
			id integer
		)",
	);
	$db += $p->send(-1);
	if ($db == 3) {
		print "База данных успешно создана!\n";
	} else {
		print "Ошибка в создании базы данных\n";
	}
	exit;
} elsif ($ARGV[0] eq "user") {
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
		"query" => "select u.nickname, u.rank, u.karma from posts p join users u where p.author_comment=1 and u.nickname=p.author"
	);
	my @result;
	my $sth = $p->send(1);
	while (my $row_res = $sth->fetchrow_hashref) {
		push(@result, $row_res);
	}
	$p->setData(\@result);
} elsif ($ARGV[0] eq "desert_posts") {
	my $n;
	GetOptions("n=i" => \$n, "format=s" => \$format, "refresh" => \$refresh);
	if (not defined $refresh) {
		$refresh = 0;
	}
	$p = Local::Request->new(
		"query" => "select p.theme, p.rank, p.stars, p.views, p.author, p.id from commenters c join posts p where c.id=p.id group by c.id having count(distinct c.nickname) < $n"
	);
	my $sth = $p->send(1);
	my @result;
	while (my $row_res = $sth->fetchrow_hashref) {
		push(@result, $row_res);
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
