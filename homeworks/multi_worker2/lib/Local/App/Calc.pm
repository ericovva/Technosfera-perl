package Local::App::Calc;

use strict;
use IO::Socket;
use lib '/home/gmoryes/Technosfera-perl/homeworks/multi_worker2/lib';
use Local::App::evaluate;
use Local::App::rpn;

#Определение обрабатываемых сигналов
#$SIG{...} = \&...;
$SIG{INT} = sub {
	unlink "result.txt";
	unlink "calc_status.txt";
};
sub start_server {
    # На вход получаем порт который будет слушать сервер занимающийся расчетами примеров
    my $port = shift;
    my $server = IO::Socket::INET->new(
	LocalPort => $port,
	Type => SOCK_STREAM,
	ReuseAddr => 1,
	Listen => 10) or die "Can't create server on port $port : $@ $/";
	
	while (my $client = $server->accept()) {
		my $child = fork();
		if ($child) {
			close($client);
			next;
		} elsif (defined $child) {
			close($server);
			#print "new connection\n";
			$client->autoflush(1);
			my $size = 0;
			$client->recv($size, 4);
			$size = unpack("L", $size);
			for (my $i = 0; $i < $size; $i++) {
				my $message;
				my $size_of_message;
				$client->recv($size_of_message, 4);
				$size_of_message = unpack("L", $size_of_message);
				$client->recv($message, $size_of_message);
				$message = unpack("a*", $message);
				my $res;
				my $err;
				eval {
					$res = calculate($message);
					send($client, pack("L/a*", "ok"), 0);
					send($client, pack("d", $res), 0);
				} or do {
					send($client, pack("L/a*", "bad"), 0);
					my $err = $@;
					send($client, pack("L/a*", $err), 0);
				}
				
				#print "res: $res or ".pack("d", $res)."\n";	
			}
			close($client);
			exit;
		} else {
			die "can't fork sorry ;( \n";
		}
	}
    # Создание сервера и обработка входящих соединений, форки не нужны 
    # Входящее и исходящее сообщение: int 4 byte + string
    # На каждое подключение отдельный процесс. В рамках одного соединения может быть передано несколько примеров
}
#start_server(8081);


sub calculate {
    my $ex = shift;
    return evaluate(rpn($ex));
    # На вход получаем пример, который надо обработать, на выход возвращаем результат
}

1;
