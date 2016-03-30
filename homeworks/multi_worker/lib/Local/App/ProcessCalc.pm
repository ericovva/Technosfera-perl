package Local::App::ProcessCalc;

use strict;
use warnings;
use IO::Socket;
use DDP;
use Exporter 'import';
use lib '/home/gmoryes/Technosfera-perl/homeworks/multi_worker/lib';
use Local::App::evaluate;
use Local::App::rpn;
our @EXPORT = ('get_from_server');
our $VERSION = '1.0';

our $status_file = './calc_status.txt';
#print(evaluate(rpn("4 -(4*-1-0)")));
#Определение обрабатываемых сигналов
#$SIG{...} = \&...;
sub min {
	my $a = shift;
	my $b = shift;
	return $a if $a < $b;
	return $b if $b <= $a;
}
my $arr = get_from_server(8082, 10);
#p($arr);
#multi_calc(1, ["1 + 2", "4 + 5"], 8081);
sub multi_calc {
    # На вход получаем 3 параметра
    my $fork_cnt = shift;  # кол-во паралельных потоков в котором мы будем обрабатывать задания
    my $jobs = shift;      # пул заданий
    my $calc_port = shift; # порт на котором доступен сетевой калькулятор
	my @equals = @{$jobs};
	my @equals_copy = @equals;
	my $needs = int((scalar(@equals) + $fork_cnt - 1) / $fork_cnt);
	my $pid;
	my $child_id = 0;
	for (my $i = 0; $i < $fork_cnt; $i++) {
		@equals = @equals[$i * $needs..min(($i + 1) * $needs - 1, scalar(@equals) - 1)];
		$pid = fork();
		if (!$pid) {
			$child_id++;
			last;
		}
		@equals = @equals_copy;
	}
	
	if (!$pid) {
		#print @equals;
		#print "\n";
		my $socket = IO::Socket::INET->new(
		PeerAddr => 'localhost',
		PeerPort => $calc_port,
		Proto => "tcp",
		Type => SOCK_STREAM) or die "не могу подключиться к localhost";
		print $socket pack("L", scalar(@equals))."\n";
		for (my $i = 0; $i < scalar(@equals); $i++) {
			print $socket pack("L/a*", $equals[$i])."\n";
			my $ans = <$socket>;
			$ans = unpack("d", $ans);
			print $ans."\n";
		}
	}
    # расчитываем сколько заданий приходится на 1 обработчик
    # запускаем необходимое кол-во процессов 
    # в каждом процессе идём по необходимым примерам, отправляем в сервер, который умеет их обрабатывать, результат записываем в файл
    # после каждого расчета, обновляем своё состояние в файле статуса $status_file (файл должен быть удалён после завершения программы, а не функции)
    # в файлеx статусе должены храниться структура {PID => {status => 'READY|PROCESS|DONE', cnt => $cnt}}, где $cnt - кол-во обработанных заданий этим обработчиком
    # в рамках одного обработчика делаем одно соединение с сервером обработки заданий, а в рамках этого соединение обрабатываем все задания
    # Исходящее и входящее сообщение имеет одинаковый формат 4-х байтовый инт + строка указанной длинны
    my $ret = [];
    # Возвращаем массив всех обработанных заданий
    return $ret;
}

sub get_from_server {
	my $port = shift;
    my $limit = shift;
    $limit .= "\n";
    # Функция получающая набор заданий с сервера
    # На вход получаем порт, который слушает сервер, и кол-во заданий которое надо вернуть
    my $socket = IO::Socket::INET->new(
	PeerAddr => 'localhost',
	PeerPort => $port,
	Proto => "tcp",
	Type => SOCK_STREAM)
	or die "Can`t connect to localhost $/";
	my $send = pack("s", $limit);
	print $socket $send."\n";
	my $ans = <$socket>;
	print $ans;
	my @answer = <$socket>;
	close($socket);
	return \@answer;
    # Создаём подключение к серверу
    # Отправляем 2-х байтный int (кол-во сообщений которое мы от него просим)
    # Получаем 4-х байтный int + последовательной сообщений состоящих их 4-х байтных интов + строк указанной длинны
    #my $ret = [];
    # Возвращаем ссылку на массив заданий
    #return $ret;
}
#p(get_from_server(8081, 5));

1;
