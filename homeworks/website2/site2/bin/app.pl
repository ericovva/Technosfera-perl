#!/usr/bin/env perl
use Dancer;
use site;
use FindBin;
use lib "$FindBin::Bin/../lib";
use rpn;
use DDP;
use tokenize;
use evaluate;
use Dancer::Plugin::RPC::XML;
use Dancer::Plugin::Auth::Basic;
use XML::RPC;
use Dancer::Session;
set session => 'YAML';
my $user_file_path = config->{"path_to_user_file"};	
xmlrpc '/rpc' => sub {
	my $users;
	my $user_file;
	my $cur_time = time;
	open($user_file, "<", $user_file_path);
	my @user_rows;
	while (my $line = <$user_file>) {
		chomp($line);
		my ($name, $pass, $project, $token, $token_data, $root, $last_rpc, $limit_rpc) = split('\\|', $line);
		if ($token_data !~ /[^0-9]/g) {
			if ($cur_time - $token_data <= config->{"default_token_live"} and ($cur_time - $last_rpc > $limit_rpc or $last_rpc == 0)) {
				$users->{$name} = $token;
				$last_rpc = time;
			}
		}
		push(@user_rows, join('|', ($name, $pass, $project, $token, $token_data, $root, $last_rpc, $limit_rpc)));
	}
	close($user_file);
	open($user_file, ">", $user_file_path);
	for my $i (@user_rows) {
		print $user_file $i."\n";
	}
	close($user_file);
	auth_basic users => $users;
	my $calc_func = {
		"calc.evaluate" => \&evaluate,
	};
	my $method = params->{method};
	my $data = params->{data};
	p $data;
	if (not exists $calc_func->{$method}) {
		#error no func
		return xmlrpc_fault(100,"Undefined method");
	} else {
		eval {
			my $ans = evaluate(rpn($data->[0]));
			return $ans;
		} or do {
			#error in calc
			#400 Bad Request («плохой, неверный запрос»)
			return xmlrpc_fault(400, $@);
		}
	}
};

dance;
