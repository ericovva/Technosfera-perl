package site;
use Dancer ':syntax';
use Dancer::Plugin::RPC::XML;
use XML::RPC;
use DDP;

our $VERSION = '0.1';
set template => 'template_toolkit';
get '/' => sub {
    template 'index';
};

get '/mypage' => sub {
	my $client = XML::RPC->new("http://localhost:3000/rpc");
	my $res = $client->call("func", "data");
	return $res;
};
get '/register' => sub {
	if (param "good") {
		template 'sucsess_reg'
	} elsif (param "login_ex") {
		template 'login_exist';
		#template 'register';
	} else {
		template 'register';
	}
};
any ['get', 'post'] => '/register_user' => sub {
	my $users;
	open($users, "<", "users.txt");
	my $login = param "login";
	my $pass = param "pass";
	while (my $line = <$users>) {
		my ($login_ex, $pass_ex) = split('#', $line);
	#	print "login_ex: $login_ex \n";
		if ($login_ex eq $login) {
			close($users);
			return redirect '/register'."?login_ex=1"
		}
	}
	close($users);
	open($users, ">>", "users.txt");
	print $users $login."#".$pass."\n";
	close($users);
	return redirect '/register' . "?good=1";
};
get '/login' => sub {
	if (param "wrong") {
		template "bad_login";
	} else {
		template 'login';
	}
};

post '/check_login' => sub {
	my $login = param "login";
	my $pass = param "pass";
	my $users;
	open($users, "<", "users.txt");
	while (my $line = <$users>) {
		chomp($line);
		my ($login_ex, $pass_ex) = split('#', $line);
		if ($login_ex eq $login and $pass_ex eq $pass) {
			return redirect '/mypage';
		}
	}
	return redirect "/login?wrong=1";
};

true;
