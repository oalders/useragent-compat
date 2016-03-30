use Test::More;

use UserAgent::Compat;

use DDP;
use Furl;
use HTTP::Tiny;
use LWP::UserAgent;
use Mojo::UserAgent;
use Try::Tiny qw( catch try );
use WWW::Mechanize;

my @ua_classes = (
    'Furl',
    'HTTP::Tiny',
    'LWP::UserAgent',
    'Mojo::UserAgent',
    'WWW::Mechanize',
);

foreach my $class (@ua_classes) {
    my $compat = UserAgent::Compat->new( user_agent => $class->new );
    ok( $compat, 'compiles' );

    my $res;
    try {
        $res = $compat->get('http://wundercharts.com');
    }
    catch {
        diag $_
    };
    ok( $res, 'get via ' . $class );
    ok( $res->is_success, 'is_success' );
    ok( $res->headers, 'headers' );
    diag( np( $res->headers ) );
}

done_testing();
