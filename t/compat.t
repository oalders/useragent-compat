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
        test_request( sub { $compat->$method($url) }, $class, $method );
        test_request(
            sub {
                $compat->request( HTTP::Request->new( uc($method) => $url ) );
            },
            $class,
            "$method via ->request"
        );
    }
}

sub test_request {
    my $cb     = shift;
    my $class  = shift;
    my $method = shift;
    try {
        $res = $cb->();
    }
    catch {
        diag $_;
        diag 'skipping further tests for this';
        next METHOD;
    };
    ok( $res,             "$method ($class)" );
    ok( $res->is_success, 'is_success' );
    ok( $res->headers,    'headers' );
    ok( $res->code,       'code: ' . $res->code );
    unless ( $method =~ m{\Ahead} ) {
        ok( $res->content, 'content' );
        diag( np( $res->{raw} ) ) unless $res->content;
    }
}
done_testing();

