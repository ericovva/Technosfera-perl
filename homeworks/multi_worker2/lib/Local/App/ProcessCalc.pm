package Local::App::ProcessCalc;

use strict;
use warnings;
use IO::Socket;
use DDP;
use JSON::XS;
use Data::Dumper;
use Exporter 'import';
use lib '/home/gmoryes/Technosfera-perl/homeworks/multi_worker2/lib';
use Local::App::evaluate;
use Local::App::rpn;
use POSIX qw(:sys_wait_h);
use List::Util 'min';
our @EXPORT = ('get_from_server');
our $VERSION = '1.0';
$SIG{INT} = sub {
	exit 1;
};
our $status_file = './calc_status.txt';
#my $arr = get_from_server(8082, 1000);
#multi_calc(30, $arr, 8081);
sub multi_calc {
	unlink $status_file;
	unlink "result.txt";
    # На вход получаем 3 параметра
    my $fork_cnt = shift;  # кол-во паралельных потоков в котором мы будем обрабатывать задания
    my $jobs = shift;      # пул заданий
    #p $arr;
    my $calc_port = shift; # порт на котором доступен сетевой калькулятор
	my @equals = @{$jobs};
	my @equals_copy = ();
	#сколько нам нужно примеров на каждый обработчик, считаем так, что бы разницы между двумя любыми была минимальной
	my $needs = int((scalar(@equals) + $fork_cnt - 1) / $fork_cnt);
	#print "need: $needs \n";
	#массив, в котором будут содержаться pid'ы детей
	my @pid = ();
	my $child_id = 0;
	my $ret = [];
	my $trueSeparate = 0;
	for (my $i = 0; $i < $fork_cnt; $i++) {
		if ($i < scalar(@equals) % $fork_cnt or scalar(@equals) % $fork_cnt == 0 or $trueSeparate) {
			for (my $j = $i * $needs; $j <= min(($i + 1) * $needs - 1, scalar(@equals) - 1); $j++) {
				$equals_copy[$j - $i * $needs] = $equals[$j];
			}
		} else {
			$needs--;
			$trueSeparate = 1;
			$i--;
			next;
		}
		$child_id++;
		push(@pid, fork());
		if ($pid[$#pid]) {
			@equals_copy = ();
			next;
		} elsif (defined $pid[$#pid]) {
			last;
		} else {
			die "can't fork bro \n";
		}
	}
	if ($pid[$#pid]) {
		#это процесс - родитель
		my $cnt = 1;
		my $mainRes;
		open($mainRes, ">>", "result.txt");
		#print join(' ', @pid);
		foreach my $i (@pid) {
			waitpid($i, 0);
			#ждем завершения i-ого ребенка
			my $exit_status = $? >> 8;
			#если статус завершения был не нулевой, то убиваем всех детей и очищаем за ними файлы
			if ($exit_status != 0) {
				kill @pid[$cnt - 1..scalar(@pid) - 1];
				for (my $j = $cnt; $j <= scalar(@pid); $j++) {
					unlink "result_$j.txt";
				}
				unlink $status_file;
				unlink "result.txt";
				die "Обработчик $i завершил работу не коректно \n";
			}
			#если все хорошо, то удаляем файл, созданный ребенком и копируем его содержимое в основной файл
			my $file;
			my @answers;
			open($file, '<', "result_$cnt.txt");
			while (my $line = <$file>) {
				push(@answers, $line);
				push(@{$ret}, $line);
			}
			close($file);
			foreach my $j (@answers) {
				print $mainRes $j;
			}
			unlink "result_$cnt.txt";
			$cnt++;
		}
		#unlink $status_file;
		close($mainRes);
	} elsif (defined $pid[$#pid]) {
		#это ребенок, он подклчючается к серверу, который умеет вычислять примеры
		my $socket = IO::Socket::INET->new(
			PeerAddr => 'localhost',
			PeerPort => $calc_port,
			Proto => "tcp",
			Type => SOCK_STREAM
		) or die "не могу подключиться к localhost";
		send($socket, pack("l", scalar(@equals_copy)), 0);
		#говорим серверу, сколько сейчас к нему придет примеров
		my $file;
		open($file, '>', "result_$child_id.txt");
		my $fileStatus;
		my $filePosition;
		#print "my pid is $$ \n";
		#это статус текущего pid
		my %hash_status = (
			"status" => 'READY',
			"cnt" => 0
		);
		my %hash;
		my $was;
		#если файла не было - создаем, иначе считываем хеш, и обновляем текущий статус
		if (-e $status_file) {
			open($fileStatus, '+<', $status_file);
			flock($fileStatus, 2);
			$was = <$fileStatus>;
			$was = JSON::XS->new->utf8->decode($was);
			%hash = %{$was};
		} else {
			open($fileStatus, '>', $status_file);
			flock($fileStatus, 2);
		}
		
		$hash{"$$"} = \%hash_status;
		seek($fileStatus, 0, 0);
		truncate($fileStatus, 0);
		print $fileStatus JSON::XS->new->utf8->encode(\%hash);
		close($fileStatus);
		#отправляем наши примеры на сервер
		for (my $i = 0; $i < scalar(@equals_copy); $i++) {
			chomp($equals_copy[$i]);
			send($socket, pack("L/a*", $equals_copy[$i])."\n", 0);
			my $ans;
			my $size_of_message;
			my $message;
			$socket->recv($size_of_message, 4);
			$size_of_message = unpack("L", $size_of_message);
			$socket->recv($message, $size_of_message);
			$message = unpack("a*", $message);
			if ($message eq "ok") {
				#print "message: $message \n";
				$socket->recv($ans, 8);
				$ans = unpack("d", $ans);
				print $file $ans."\n";
			} else {
				#print "message: $message ";
				my $err_size;
				$socket->recv($err_size, 4);
				$err_size = unpack("L", $err_size);
				my $error;
				$socket->recv($error, $err_size);
				$error = unpack("a*", $error);
				#print "error: $error \n";
				print $file $error;
			}
			
			#обновляем статистику
			my @saveFile;
			$hash_status{"status"} = 'PROCESS';
			$hash_status{"cnt"}++;
			open($fileStatus, '+<', $status_file);
			flock($fileStatus, 2);
			$was = <$fileStatus>;
			if (!defined $was) {
				$was = "{}";
			}
			$was = JSON::XS->new->utf8->decode($was);
			%hash = %{$was};
			$hash{"$$"} = \%hash_status;
			seek($fileStatus, 0, 0);
			truncate($fileStatus, 0);
			print $fileStatus JSON::XS->new->utf8->encode(\%hash);
			close($fileStatus);
			#end of status file
		}
		my @saveFile;
		#когда все примеры отослали, и на каждый записали ответ, пишем в стутус DONE
		$hash_status{"status"} = 'DONE';
		open($fileStatus, '+<', $status_file);
		flock($fileStatus, 2);
		$was = <$fileStatus>;
		if (!defined $was) {
			$was = "{}";
		}
		$was = JSON::XS->new->utf8->decode($was);
		%hash = %{$was};
		$hash{"$$"} = \%hash_status;
		seek($fileStatus, 0, 0);
		truncate($fileStatus, 0);
		print $fileStatus JSON::XS->new->utf8->encode(\%hash);
		close($fileStatus);
		close($file);
		exit;
	} else {
		die "не могу запустить дочерний процесс \n";
	}
    
    # Возвращаем массив всех обработанных заданий
    return $ret;
}

sub get_from_server {
	my $port = shift;
    my $limit = shift;
    # Функция получающая набор заданий с сервера
    # На вход получаем порт, который слушает сервер, и кол-во заданий которое надо вернуть
    my $socket = IO::Socket::INET->new(
		PeerAddr => 'localhost',
		PeerPort => $port,
		Proto => "tcp",
		Type => SOCK_STREAM
	) or die "Can`t connect to localhost $/";
	$limit = pack("l", $limit);
	send($socket, $limit, 0);
	my @answer = <$socket>;
	close($socket);
	return \@answer;
}
1;
