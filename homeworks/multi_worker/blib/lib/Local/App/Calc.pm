package Local::App::Calc;

use strict;
use IO::Socket;
use lib '/home/gmoryes/Technosfera-perl/homeworks/multi_worker/lib';
use Local::App::evaluate;
use Local::App::rpn;

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
			print "new connection\n";
			$client->autoflush(1);
			my $size = <$client>;
			chomp($size);
			print "SIZE: $size \n";
			print $client "$size\n";
			for (my $i = 0; $i < $size; $i++) {
				my $message = <$client>;
				chomp($message);
				$message = unpack("L/a*", $message);
				print "mes: $message \n";
				my $res = calculate($message);
				print "res: $res or ".pack("d", $res)."\n";
				print $client $res."\n";
			}
			close($client);
			exit;
		} else {
			die "can't fork sorry ;( \n";
		}
	}
}
#start_server(8081);


sub calculate {
    my $ex = shift;
    return evaluate(rpn($ex));
    # На вход получаем пример, который надо обработать, на выход возвращаем результат
}

1;
