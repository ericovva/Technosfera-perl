package Local::App::ProcessCalc;

use strict;
use warnings;
use IO::Socket;
use DDP;
use JSON::XS;
use Data::Dumper;
use Exporter 'import';
use lib '/home/gmoryes/Technosfera-perl/homeworks/multi_worker/lib';
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
#multi_calc(35, $arr, 8081);
sub multi_calc {
	unlink $status_file;
	unlink "result.txt";
    # На вход получаем 3 параметра
    my $fork_cnt = shift;  # кол-во паралельных потоков в котором мы будем обрабатывать задания
    my $jobs = shift;      # пул заданий
    my $calc_port = shift; # порт на котором доступен сетевой калькулятор
	my @equals = @{$jobs};
	my @equals_copy = ();
	my $needs = int((scalar(@equals) + $fork_cnt - 1) / $fork_cnt);
	print "need: $needs \n";
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
		my $cnt = 1;
		my $mainRes;
		open($mainRes, ">>", "result.txt");
		print join(' ', @pid);
		foreach my $i (@pid) {
			waitpid($i, 0);
			my $exit_status = $? >> 8;
			if ($exit_status != 0) {
				kill @pid[$cnt - 1..scalar(@pid) - 1];
				for (my $j = $cnt; $j <= scalar(@pid); $j++) {
					unlink "result_$j.txt";
				}
				unlink $status_file;
				unlink "result.txt";
				die "Обработчик $i завершил работу не коректно \n";
			}
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
		close($mainRes);
	} elsif (defined $pid[$#pid]) {
		my $socket = IO::Socket::INET->new(
		PeerAddr => 'localhost',
		PeerPort => $calc_port,
		Proto => "tcp",
		Type => SOCK_STREAM) or die "не могу подключиться к localhost";
		print $socket scalar(@equals_copy)."\n";
		my $size = <$socket>;
		chomp($size);
		my $file;
		open($file, '>', "result_$child_id.txt");
		my $fileStatus;
		my $filePosition;
		print "my pid is $$ \n";
		my %hash_status = (
			"status" => 'READY',
			"cnt" => 0
		);
		my %hash;
		my $was;
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
		for (my $i = 0; $i < scalar(@equals_copy); $i++) {
			chomp($equals_copy[$i]);
			print $socket pack("L/a*", $equals_copy[$i])."\n";
			my $ans = <$socket>; 
			chomp($ans);
			print $file $ans."\n";
			#status file
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
	Type => SOCK_STREAM)
	or die "Can`t connect to localhost $/";
	my $send = $limit;
	send($socket, $send."\n", 0);
	my @answer = <$socket>;
	close($socket);
	return \@answer;
}
1;
