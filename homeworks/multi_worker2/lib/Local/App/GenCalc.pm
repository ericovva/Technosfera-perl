package Local::App::GenCalc;

use strict;
use warnings;
use DDP;
use IO::Socket;
use IO::Socket "getnameinfo";
use Data::Dumper;
use Exporter 'import';
our @EXPORT = ('start_server', 'get');
use Time::HiRes 'ualarm';
my $file_path = './calcs.txt';
my $timer = 100;
sub new_one {
    # Функция вызывается по таймеру каждые 100
    my $calcTxt;
    open($calcTxt, ">>", $file_path);
    my $new_row = join $/, int(rand(5)).'  '.int(rand(5)), 
                  int(rand(2)).' + '.int(rand(5)).' * '.int(int(rand(10))), 
                  '('.int(rand(10)).' + '.int(rand(8)).') * '.int(rand(7)), 
                  int(rand(5)).'  '.int(rand(6)).' * '.int(rand(8)).' ^ '.int(rand(12)), 
                  int(rand(20)).' + '.int(rand(40)).' * '.int(rand(45)).' ^ '.int(rand(12)), 
                  (int(rand(12))/(int(rand(17))+1)).' * ('.(int(rand(14))/(int(rand(30))+1)).' - '.int(rand(10)).') / '.(int(rand(10)) + 1).'.0 ^ 0.'.int(rand(6)),  
                  int(rand(8)).' + 0.'.int(rand(10)), 
                  int(rand(10)).'  .5',
                  int(rand(10)).' + .5e0',
                  int(rand(10)).' + .5e1',
                  int(rand(10)).' + .5e+1', 
                  int(rand(10)).' + .5e-1', 
                  int(rand(10)).'  .5e+1 * 2';
    # Далее происходить запись в файл очередь
    my @toAdd = split(/\n/, $new_row);
    foreach my $i (@toAdd) {
		print $calcTxt $i."\n";
	}
	close($calcTxt);
}
my $goIn = 0;
$SIG{ALRM} = sub {
	new_one();
	$goIn = 1;
	ualarm($timer);
};
$SIG{INT} = sub {
	unlink "calcs.txt";
};
my $lastPos = 0;
sub start_server {
    # На вход приходит номер порта который будет слушат сервер для обработки запросов на получение данных
    my $port = shift;
    my $server = IO::Socket::INET->new(
	LocalPort => $port,
	Type => SOCK_STREAM,
	ReuseAddr => 1,
	Listen => 10) or die "Can't create server on port $port : $@ $/";
	ualarm($timer);
	while(my $client = $server->accept() or $goIn) {
		if ($goIn) {
			$goIn = 0;
			next if !defined $client;
		}
		ualarm(0);
		$client->autoflush(1);
		my $N;
		$client->recv($N, 4);
		$N = unpack("l", $N);
		my $other = getpeername($client);
		my ($arr, $host, $service) = getnameinfo($other);
		print "New connection from: $host:$service $/";
		print $client join("\n", @{get($N)});
		close($client);
		ualarm($timer);
	}
	close($server);
}
#start_server(8082);


sub get {
    # На вход получаем кол-во запрашиваемых сообщений
    my $limit = shift;
	my $fh;
	open($fh, "<", "./calcs.txt") or die $!;
	seek($fh, $lastPos, 0);
	my $ret = []; # Возвращаем ссылку на массив строк
    # Открытие файла, чтение N записей
    # Надо предусмотреть, что файла может не быть, а так же в файле может быть меньше сообщений чем запрошено
    my $i;
	for ($i = 0; $i < $limit; $i++) {
		my $toAdd = <$fh>;
		if ($toAdd eq "") {
			$i--;
			last;
		}
		chomp($toAdd);
		$ret->[$i] = $toAdd;
	}
	if ($i != $limit) {
		print "мало примеров, просят больше \n";
	}
    $lastPos = tell($fh);
    close($fh);
    return $ret;
}

1;
