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
my $user_file_path = config->{"path_to_user_file"};	 
get '/' => sub {
    template 'index';
};
sub clear_write {
	unlink "logs.txt";
};

sub clear_session {
	session->destroy;
}

sub deb {
	my $file;
	open($file, ">>", "logs.txt");
	my $info = shift;
	print $file $info;
	close($file);
}

sub exist_login {
	my $users;
	open($users, "<", $user_file_path);
	my $login = shift;
	while (my $line = <$users>) {
		chomp($line);
		my ($login_ex) = ($line =~ m/^(.*?)#/);
		#print "login_ex: $login_ex \n";
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
	open($users, "<", $user_file_path);
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

hook 'before' => sub {
	if (request->path_info eq "/register") {
		my $file;
		if (!open($file, "<", $user_file_path)) {
			open($file, ">", $user_file_path);
			print $file "UserName#UserPassword#UserProject#token#tokenData#1#last_rpc#limit_rpc\n";
		}
	}
};

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
			$templ->{"auth_token"} = session("auth_token");
			if (param "login_ex") {
				$templ->{"info_for_user"} = "Такой логин уже кем-то занят";
			} elsif (param "no_info") {
				$templ->{"info_for_user"} = "Нет информации по данному пользователю";
			}
			my $content;
			$content .= '<table style="width:100%">';
			my $users;
			open($users, "<", $user_file_path);
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
		my $templ = {user_name => session("user_name"), auth_token => session("auth_token")};
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

#delete?from=root&who=login&is_root=1
post '/delete' => sub {
	if (!session("log_in")) {
		return redirect '/login';
	}
	if (param("auth_token") ne session("auth_token")) {
		return redirect '/login';
	}
	my $info_session = get_info_user(session("user_name"));
	if (not defined $info_session) {
		return redirect "/root?no_info=1" if param "is_root";
		return redirect "/mypage?no_info=1";
	}
	if (session("user_name") eq param "who" or $info_session->{"root"}) {
		#delete
		my $file;
		open($file, "<", $user_file_path);
		my @new_list;
		while(my $line = <$file>) {
			chomp($line);
			my ($login) = ($line =~ m/^(.*?)#/);
			if ($login ne param "who") {
				push(@new_list, $line);
			}
		}
		close($file);
		open($file, ">", $user_file_path);
		for my $i(@new_list) {
			print $file $i."\n";
		}
		close($file);
		return redirect "/root" if param "is_root";
		clear_session();
		return redirect '/login?delete=1';
	} else {
		return redirect "/root?access=1" if param "is_root";
		return redirect "/mypage?access=1";
	}
};
#change_data?from=root&who=login&login=new_login&pass=new_pass&is_root=1
post '/change_data' => sub {
	if (!session("log_in")) {
		return redirect '/login';
	} else {
		if (param("auth_token") ne session("auth_token")) {
			return redirect '/login';
		}
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
		if (param "get_token") {
			my $token = time;
			my $date = time;
			clear_write();
			$token = ($token *  int(rand(177239))) % (1e9 + 7);
			$old_info{"token"} = $token;
			$old_info{"token_data"} = $date;
		}
		my @prop_names = ("login", "pass", "project", "token", "token_data");
		my @root_prop_names = ("root", "last_rpc", "limit_rpc");
		my %param;
		for my $i (@prop_names) {
			$param{$i} = param $i if param $i;
		}
		for my $i (@root_prop_names) {
			$param{$i} = param $i if param $i;
		}
		if (defined param "is_root") {
			$param{param "change_value"} = param "value";
		}
		my @user_prop;
		for my $i (@prop_names) {
			if (exists $param{$i}) {
				push(@user_prop, $param{$i});
			} else {
				push(@user_prop, $old_info{$i});
			}
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
		open($users, "<", $user_file_path);
		my $cont = 0;
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
		unlink $user_file_path;
		open($users, ">", $user_file_path);
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
	return "hello";
};

any ['get', 'post'] => '/register' => sub {
	if (session("log_in")) {
		return redirect '/mypage';
	}
	if (param "login") {
		my $login = param "login";
		if ($login =~ /[^A-Za-z@\.1-9]+/gm) {
			return redirect '/register?wrong_syntax=1';
		}
		if (param("pass") =~ /[^A-Za-z@\.\s:\/\\1-9]/gm) {
			return redirect '/register?wrong_syntax=1';
		}
		if (param("pass") =~ /[^A-Za-z@\.\s:\/\\1-9]/gm) {
			return redirect '/register?wrong_syntax=1';
		}
		if (exist_login($login)) {
			return redirect '/register?login_ex=1';
		}
		my $pass = param "pass";
		my $projectName = param "project";
		my $users;
		open($users, ">>", $user_file_path);
		#login.password.project.token.token_data.root.last_rpc.limit_rpc
		print $users $login."#".$pass."#".$projectName."#"."NoToken"."#"."NoTokenData"."#"."0"."#"."0"."#"."100"."\n";
		close($users);
		return redirect '/register?good=1';
	} elsif (param "good") {
		template 'sucsess_reg'
	} elsif (param "login_ex") {
		template 'register' => {"info_for_user" => "Такой логин уже занят"};
	} elsif (param "wrong_syntax") {
		template 'register' => {"info_for_user" => "Введные данные содержат недопустимый символ:"};
	} else {
		template 'register';
	}
};
get '/login' => sub {
	my $templ;
	$templ->{"page_name"} = "Авторизация";
	if (param "wrong") {
		$templ->{"info_for_user"} = "Неверный логин или пароль";
	} elsif (param "log_out") {
		clear_session();
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
	open($users, "<", $user_file_path);
	while (my $line = <$users>) {
		chomp($line);
		my ($login_ex, $pass_ex) = split('#', $line);
		if ($login_ex eq $login and $pass_ex eq $pass) {
			session "log_in" => 1;
			session "user_name" => $login;
			session("auth_token", int(rand(9030133)) % (1e9 + 7));
			return redirect '/mypage';
		}
	}
	return redirect "/login?wrong=1";
};

true;
