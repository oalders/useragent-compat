use Test::More;

use UserAgent::Compat;

use DDP;
use Devel::Confess;
use Furl;
use HTTP::Request;
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

METHOD:
    foreach my $method ( 'delete', 'get', 'head', 'patch', 'post', 'put' ) {
        my $res;
        my $url = 'http://127.0.0.1:3000';
        diag '-'x40;
        try {
            $res
                = $method ne 'patch'
                ? $compat->$method($url)
                : $compat->request( HTTP::Request->new( PATCH => $url ) );
        }
        catch {
            diag $_;
            #exit;
            next METHOD;
        };
        ok( $res,             "$method via " . $class );
        ok( $res->is_success, 'is_success' );
        ok( $res->headers,    'headers' );
        ok( $res->code,       'code: ' . $res->code );
        unless ( $method eq 'head' ) {
            diag( np( $res ) );
            ok( $res->content, 'content' );
        }
        #diag( np( $res->headers ) );

        #    diag( np( $res->as_object ) );
    }
}

done_testing();

