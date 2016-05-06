package site;
use Dancer ':syntax';
use XML::Simple;
use XML::RPC;
use DateTime;
use DDP;
use rpn;
use tokenize;
use evaluate;
use Dancer::Plugin::Auth::Basic;
use Dancer::Request;
use LWP::UserAgent;
use Dancer::Config::Object;

our $VERSION = '0.1';
set template => 'template_toolkit';
get '/' => sub {
    template 'index';
};
sub clear_write {
	unlink "logs.txt";
};
sub deb {
	my $file;
	open($file, ">>", "logs.txt");
	my $info = shift;
	print $file $info;
	close($file);
}
sub exist_login {
	my $users;
	open($users, "<", "users.txt");
	my $login = shift;
	while (my $line = <$users>) {
		chomp($line);
		my ($login_ex) = ($line =~ m/^(.*?)#/);
	#	print "login_ex: $login_ex \n";
		if ($login_ex eq $login) {
			close($users);
			return 1;
		}
	}
	close($users);
	return 0;
}

sub get_info_user {
	my $users;
	open($users, "<", "users.txt");
	my $login = shift;
	while (my $line = <$users>) {
		chomp($line);
		my ($login_ex) = ($line =~ m/^(.*?)#/);
		if ($login_ex eq $login) {
			my @res = my ($name, $pass, $project, $token, $token_data, $root, $last_rpc, $limit_rpc) = split('#', $line);
			my $res = {
				"login" => $name,
				"pass" => $pass,
				"project" => $project,
				"token" => $token,
				"token_data" => $token_data,
				"root" => $root,
				"last_rpc" => $last_rpc,
				"limit_rpc" => $limit_rpc,
			};
			return $res;
		}
	}
	close($users);
	return undef;
}
get '/root' => sub {
	if (!session("log_in")) {
		return redirect '/login';
	} else {
		my $info_user = get_info_user(session("user_name"));
		if (!$info_user->{"root"}) {
			return redirect '/mypage?access=1';
		} else {
			my $templ;
			$templ->{"time"} = time;
			if (param "login_ex") {
				$templ->{"info_for_user"} = "Такой логин уже кем-то занят";
			} elsif (param "no_info") {
				$templ->{"info_for_user"} = "Нет информации по данному пользователю";
			}
			my $content;
			$content .= '<table style="width:100%">';
			my $users;
			open($users, "<", "users.txt");
			while (my $line = <$users>) {
				chomp($line);
				$content .= "<tr>";
				my @prop = split('#', $line);
				for my $i (@prop) {
					$content .= "<td>".$i."</td>";
				}
				$content .= "</tr>";
			}
			close($users);
			$content .= "</table>";
			$templ->{"user_name"} = session("user_name");
			$templ->{"content"} = $content;
			template 'root' => $templ;
		}
	}
};
any ['get', 'post'] => '/mypage' => sub {
	if (!session("log_in")) {
		return redirect '/login';
	} else {
		my $templ = {user_name => session("user_name")};
		if (param "change") {
			$templ->{"info_for_user"} = "Данные успешно изменены";
		} elsif (param "no_info") {
			$templ->{"info_for_user"} = "Произошла ошибка, информации по вам не найдено";
		} elsif (param "login_ex") {
			$templ->{"info_for_user"} = "Такой логин уже занят";
		} elsif (param "access") {
			$templ->{"info_for_user"} = "Недостаточно прав";
		}
		my $user = get_info_user(session("user_name"));
		if (defined $user) {
			if ($user->{"token"} ne "NoToken") {
				my $time_now = time;
				if ($time_now - $user->{"token_data"} > config->{"default_token_live"}) {
					$templ->{"token"} = "Ваш токен не действительный";
				} else {
					$templ->{"token"} = "Ваш токен: ".$user->{"token"};
				}
			} else {
				$templ->{"token"} = "У вас нет токена, нажмите \"Получить токен\"";
			}
		} else {
			return redirect '/login';
		}
		template 'mypage' => $templ;
	}
};

any ['get', 'post'] => '/get_token' => sub {
	#token only for 5 minutes
	if (!session("log_in")) {
		return redirect '/login';
	} else {
		my $token = time;
		my $date = time;
		clear_write();
		$token = ($token *  int(rand(177239))) % (1e9 + 7);
		return redirect "/change_data?from=".session("user_name")."&token=$token&token_data=$date";
	}
};
any ['get', 'post'] => '/xml' => sub {
	my $users;
	my $user_file;
	my $cur_time = time;
	open($user_file, "<", "users.txt");
	my @user_rows;
	while (my $line = <$user_file>) {
		chomp($line);
		my ($name, $pass, $project, $token, $token_data, $root, $last_rpc, $limit_rpc) = split('#', $line);
		if ($token_data !~ /[^0-9]/g) {
			if ($cur_time - $token_data <= config->{"default_token_live"} and ($cur_time - $last_rpc > $limit_rpc or $last_rpc == 0)) {
				$users->{$name} = $token;
				$last_rpc = time;
			}
		}
		push(@user_rows, join('#', ($name, $pass, $project, $token, $token_data, $root, $last_rpc, $limit_rpc)));
	}
	close($user_file);
	open($user_file, ">", "users.txt");
	for my $i (@user_rows) {
		print $user_file $i."\n";
	}
	close($user_file);
	auth_basic users => $users;
    my $request = request->body;
    $request = XML::Simple->new()->XMLin($request);
    my $calc_func = {
		"calc.evaluate" => \&evaluate,
	};
    if (not exists $calc_func->{$request->{"methodName"}}) {
		#error no func
		my $response = "<methodResponse><fault><value><string>No such function</string></value></fault></methodResponse>";
		return $response;
	} else {
		my $value = $request->{"params"}->{"param"}->{"value"}->{"string"};
		eval {
			my $ans = evaluate(rpn($value));
			my $response = "<methodResponse><params><param><value><double>".$ans."</double></value></param></params></methodResponse>";
			return $response;
		} or do {
			#error in calc
			my $response = "<methodResponse><fault><value><string>".$@."</string></value></fault></methodResponse>";
			p $response;
			return $response;
		}
	}
};
#delete?from=root&who=login&is_root=1

any ['get', 'post'] => '/delete' => sub {
	my $info_session = get_info_user(session("user_name"));
	if (not defined $info_session) {
		return redirect "/root?no_info=1" if param "is_root";
		return redirect "/mypage?no_info=1";
	}
	if (session("user_name") eq param "who" or $info_session->{"root"}) {
		#delete
		my $file;
		open($file, "<", "users.txt");
		my @new_list;
		while(my $line = <$file>) {
			chomp($line);
			my ($login) = ($line =~ m/^(.*?)#/);
			if ($login ne param "who") {
				push(@new_list, $line);
			}
		}
		close($file);
		open($file, ">", "users.txt");
		for my $i(@new_list) {
			print $file $i."\n";
		}
		close($file);
		return redirect "/root" if param "is_root";
		session "user_name" => undef;
		session "log_in" => 0;
		return redirect '/login?delete=1';
	} else {
		return redirect "/root?access=1" if param "is_root";
		return redirect "/mypage?access=1";
	}
};
#change_data?from=root&who=login&login=new_login&pass=new_pass&is_root=1

any ['get', 'post'] => '/change_data' => sub {
	if (!session("log_in")) {
		return redirect '/login';
	} else {
		my $login;
		my $from_user_info = get_info_user(param "from");
		if (!defined $from_user_info) {
			return redirect '/mypage';
		}
		if (defined(param "is_root")) {
			if (!$from_user_info->{"root"}) {
				return redirect '/mypage';
			}
			$login = param "who";
		} else {
			$login = session("user_name");
		}
		my $old_info = get_info_user($login);
		if (not defined $old_info) {
			return redirect '/mypage?no_info=1' if !(defined (param "is_root"));
			return redirect '/root?no_info=1';
		}
		
		my %old_info = %{$old_info};
		my @prop_names = ("login", "pass", "project", "token", "token_data");
		my @root_prop_names = ("root", "last_rpc", "limit_rpc");
		my %param;
		for my $i (@prop_names) {
			$param{$i} = param $i if param $i;
		}
		#$param{"root"} = param "root" if param "root";
		for my $i (@root_prop_names) {
			$param{$i} = param $i if param $i;
		}
		if (defined param "is_root") {
			$param{param "change_value"} = param "value";
		}
		my @user_prop;
		my $cnt = 0;
		for my $i (@prop_names) {
			if (exists $param{$i}) {
				$user_prop[$cnt] = $param{$i};
			} else {
				$user_prop[$cnt] = $old_info{$i};
			}
			$cnt++;
		}
		for my $i (@root_prop_names) {
			if (exists($param{$i}) and $from_user_info->{"root"}) {
				push(@user_prop, $param{$i});
			} else {
				push(@user_prop, $old_info{$i});
			}
		}
		if ($user_prop[0] ne $login) {
			if (exist_login($user_prop[0])) {
				return redirect '/mypage?login_ex=1' if !param "is_root";
				return redirect '/root?login_ex=1';
			}
		}
		my @last_rows;
		my $users;
		open($users, "<", "users.txt");
		my $cont = 0;
		p @user_prop;
		while (my $line = <$users>) {
			chomp($line);
			if (!$cont) {
				my ($login_ex) = ($line =~ m/^(.*?)#/);
				if ($login_ex eq $login) {
					$line = join('#', @user_prop);
					$cont = 1;
				}
			}
			push(@last_rows, $line);
		}
		close($users);
		unlink "users.txt";
		open($users, ">", "users.txt");
		foreach my $i (@last_rows) {
			print $users $i;
			print $users "\n";
		}
		close($users);
		session "user_name" => $user_prop[0] if !(defined(param "is_root"));
		if (defined param "is_root") {
			return redirect '/root';
		} else {
			return redirect '/mypage?change=1';
		}
	}
};

get '/register' => sub {
	if (session("log_in")) {
		return redirect '/mypage';
	}
	if (param "good") {
		template 'sucsess_reg'
	} elsif (param "login_ex") {
		template 'login_exist';
	} else {
		template 'register';
	}
};
any ['get', 'post'] => '/register_user' => sub {
	
	my $login = param "login";
	if (exist_login($login)) {
		return redirect '/register?login_ex=1';
	}
	my $pass = param "pass";
	my $projectName = param "project";
	my $users;
	open($users, ">>", "users.txt");
	#login.password.project.token.token_data.root.last_rpc.limit_rpc
	print $users $login."#".$pass."#".$projectName."#"."NoToken"."#"."NoTokenData"."#"."0"."#"."0"."#"."100"."\n";
	close($users);
	return redirect '/register' . "?good=1";
};
get '/login' => sub {
	my $templ;
	$templ->{"page_name"} = "Авторизация";
	if (param "wrong") {
		$templ->{"info_for_user"} = "Неверный логин или пароль";
	} elsif (param "log_out") {
		session "user_name" => undef;
		session "log_in", 0;
		$templ->{"info_for_user"} = "Вы успешно вышли из своего профиля";
	} elsif (param "delete") {
		$templ->{"info_for_user"} = "Страница успешно удалена!";
	}
	if (session("log_in")) {
		return redirect '/mypage';
	}
	template 'login' => $templ;
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
			session "log_in" => 1;
			session "user_name" => $login;
			return redirect '/mypage';
		}
	}
	return redirect "/login?wrong=1";
};

true;
