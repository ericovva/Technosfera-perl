use XML::RPC::Fast;
use XML::RPC::UA::LWP;
use MIME::Base64;
use DDP;
my $uri = "http://localhost:3000/rpc";
my $rpc = XML::RPC::Fast->new(
	$uri,
	ua => XML::RPC::UA::LWP->new(
		ua      => 'Dancer site',
		timeout => 3,
	),
);
$rpc->{"ua"}->{"lwp"}->default_header("Authorization" => "Basic ".encode_base64("root:25650294"));
my $res = $rpc->call("calc.evaluate", "123 + 7 ^ 2 - (3 / 123 )");
#xml ответ в $rpc->{"xml_in"}
p $res;
