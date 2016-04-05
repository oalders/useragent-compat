package Mocker::Server;

use Mojolicious::Lite;

del '/' => sub {
    my $c = shift;
    $c->render( text => 'DELETE OK' );
};

get '/' => sub {
    my $c = shift;
    $c->render( text => 'GET OK' );
};

patch '/' => sub {
    my $c = shift;
    $c->render( text => 'POST OK' );
};

post '/' => sub {
    my $c = shift;
    $c->render( text => 'POST OK' );
};

put '/' => sub {
    my $c = shift;
    $c->render( text => 'PUT OK' );
};

sub to_app {
    app->secrets( ['Tempus fugit'] );
    app->start;
}

to_app();
