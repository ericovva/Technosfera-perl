use DateTime;
use DDP;
use warnings;
use HTTP::Request;
use LWP::UserAgent;

my $address = "localhost";
my $port = "3000";
my $username = "root";
my $pass = "pass";

my $browser = LWP::UserAgent->new;
my $req =  HTTP::Request->new( POST => "http://localhost:3000/xml");
$req->content("<methodCall>
   <methodName>calc.evaluate</methodName>
   <params>
     <param>
         <value><string>1 +(9()+ 2 - 3 ^ 5</string></value>
     </param>
   </params>
 </methodCall>");
$req->authorization_basic( "gmoryes", "741414761" );
my $page = $browser->request( $req );
p $page->as_string;
