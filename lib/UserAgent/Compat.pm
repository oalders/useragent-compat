use strict;
use warnings;
package UserAgent::Compat;

use Scalar::Util qw( blessed );

sub new {
    my $class = shift;
    my %args  = @_;

    die 'You must provide a user_agent arg' unless $args{user_agent};
    return bless { user_agent => $args{user_agent} }, $class;
}

sub delete {
    my $self = shift;
    return $self->_res( 'delete', @_ );
}

sub get {
    my $self = shift;
    return $self->_res( 'get', @_ );
}

sub head {
    my $self = shift;
    return $self->_res( 'head', @_ );
}

sub post {
    my $self = shift;
    return $self->_res( 'post', @_ );
}

sub put {
    my $self = shift;
    return $self->_res( 'put', @_ );
}

sub request {
    my $self = shift;
    my $req  = shift;
    my $res;

    if ( $self->{user_agent}->isa('HTTP::Tiny') ) {
        my @args = (
            $req->uri, $req->method,
            { headers => $req->headers->flatten || [], content => $req->content }
        );
        $res = $self->{user_agent}->request(@args);
    }
    else {
        $res = $self->{user_agent}->request($req);
    }
    return UserAgent::Compat::Response->new($res);
}

sub _res {
    my $self   = shift;
    my $method = shift;
    my $res    = $self->{user_agent}->$method(@_);
    return UserAgent::Compat::Response->new($res);
}

1;
package UserAgent::Compat::Response;

use strict;
use warnings;

use Scalar::Util qw( blessed );

# Furl              Furl::Response
# HTTP::Tiny        HashRef
# LWP::UserAgent    HTTP::Response
# Mojo::UserAgent   Mojo::Transaction::HTTP
# WWW::Mechanize    HTTP::Response

sub new {
    my $class = shift;
    my $res   = shift;

    die 'You must provide a response object' unless $res;
    return bless { raw => $res }, $class;
}

sub code {
    my $self = shift;
    unless ( blessed( $self->{raw} ) ) {
        return $self->{raw}->{status};
    }

    if ( $self->{raw}->isa('Mojo::Transaction::HTTP') ) {
        return $self->{raw}->res->code;
    }

    return $self->{raw}->code;
}

sub content {
    my $self = shift;
    unless ( blessed( $self->{raw} ) ) {
        return $self->{raw}->{content};
    }

    if ( $self->{raw}->isa('Mojo::Transaction::HTTP') ) {
        return $self->{raw}->res->body;
    }

    return $self->{raw}->content;
}

sub as_object {
    my $self = shift;
    return $self->{raw};
}

sub headers {
    my $self = shift;
    my $raw  = $self->{raw};

    # HTTP::Tiny returns a HashRef
    unless ( blessed($raw) ) {
        return $raw->{headers};
    }

    if ( $raw->isa('Mojo::Transaction::HTTP') ) {
        return $raw->res->headers->to_hash;
    }

    if ( $raw->can('headers') ) {
        return [ $raw->headers->flatten ];
    }
}

sub is_success {
    my $self = shift;
    my $raw  = $self->{raw};

    # HTTP::Tiny returns a HashRef
    unless ( blessed($raw) ) {
        return $raw->{success};
    }

    # Furl::Response, HTTP::Response
    if ( $raw->can('is_success') ) {
        return $raw->is_success && !$raw->header('X-Died');
    }

    # Mojo::Transaction::HTTP
    return substr( $raw->res->code, 0, 1 ) == 2;
}

1;

