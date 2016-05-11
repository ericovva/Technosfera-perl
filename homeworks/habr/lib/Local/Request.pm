package Local::Request;

use DDP;
use DBI;
use HTTP::Request;
use LWP::UserAgent;
use Config::Simple;

#Чтобы точки выводились в "online"
$| = 1;


sub showMe {
	my ($self) = @_;
	p $self;
}
sub init {
	
}
sub new {
	my ($self, %args) = @_;
	my $ret = bless \%args, $self;
	$ret->{"config"} = Config::Simple->new("config.ini");
	$ret->init();
	return $ret;
};

sub get_html {
	my ($self, $filename) = @_;
	my $html_text;
	open($html_text, ">", $filename);
	my $user_agent = LWP::UserAgent->new();
	my $url = $self->{"url"};
	$user_agent->agent("Habr Grabber");
	my $req = HTTP::Request->new(GET=>$url);
	my $resp = $user_agent->request($req);
	print $html_text $resp->content();
	close($html_text);
}

sub config {
	my ($self, $param) = @_;
	return $self->{"config"}->param($param);
}

sub send {
	my ($self, $all, $params) = @_;
	my $dbh = DBI->connect(
		$self->{"config"}->param("database.name").$self->{"config"}->param("database.filename"), 
		$self->{"config"}->param("database.login"), 
		$self->{"config"}->param("database.password"),
		{sqlite_use_immediate_transaction => 1,}
	);
	my $sth = $dbh->prepare($self->{"query"});
	#p $self;
	print '.';
	if ($sth->execute(@{$params})) {
		return 1 if $all == -1;
	} else {
		return 0;
	}
	return $sth if $all == 1;
	return $sth->fetchrow_hashref() if not defined $all;
}

sub json {
	my ($self) = @_;
	print "\n";
	if (!exists($self->{"error"})) {
		if (defined($self->{"data"})) {
			return JSON::XS->new->encode($self->{"data"});
		}
		return undef;
	} else {
		warn $self->{"error"};
		return undef;
	}
}

sub xml {
	my ($self, $xml_filename) = @_;
	my $dump = XML::Dumper->new();
	if (!exists($self->{"error"})){
		if (defined $self->{"data"}) {
			$dump->pl2xml($self->{"data"}, $xml_filename);
		} else {
			return undef;
		}
	} else {
		warn $self->{"error"};
		return undef;
	}
}

sub setData {
	my ($self, $data) = @_;
	$self->{"data"} = $data;
}

sub getData {
	my ($self) = @_;
	return $self->{"data"};
}

sub getError {
	my ($self) = @_;
	return $self->{"error"} if exists($self->{"error"});
	return undef;
}

1;

