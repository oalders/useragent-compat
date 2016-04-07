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

sub patch {
    my $self = shift;
    if ( $self->{user_agent}->isa('Mojo::UserAgent') ) {
        return $self->_res( 'patch', @_ );
    }
    my $req
        = HTTP::Request->new( PATCH => shift );    # some data being lost here
    return $self->request($req);
}

sub post {
    my $self = shift;
    return $self->_res( 'post', @_ );
}

sub put {
    my $self = shift;
    return $self->_res( 'put', @_ );
}

sub _raw {
    my $self = shift;
    return $self->{raw};
}

sub request {
    my $self = shift;
    my $req  = shift;
    my $res;

    if ( $self->{user_agent}->isa('HTTP::Tiny') ) {
        my @args = (
            $req->method, $req->uri,
            {
                headers => { $req->headers->flatten }
                ,    # this is potentially wrong
                content => $req->content
            }
        );
        $res = $self->{user_agent}->request(@args);
    }
    elsif ( !$self->{user_agent}->isa('Mojo::UserAgent') ) {
        $res = $self->{user_agent}->request($req);
    }
    else {
        my $http_verb = lc $req->method;
        $res = $self->$http_verb(
            $req->uri->as_string,
            { $req->headers->flatten }
        )->{raw};
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
    unless ( blessed( $self->_raw ) ) {
        return $self->_raw->{status};
    }

    if ( $self->_raw->isa('Mojo::Transaction::HTTP') ) {
        return $self->_raw->res->code;
    }

    return $self->_raw->code;
}

sub content {
    my $self = shift;
    unless ( blessed( $self->_raw ) ) {
        return $self->_raw->{content};
    }

    if ( $self->_raw->isa('Mojo::Transaction::HTTP') ) {
        return $self->_raw->res->body;
    }

    return $self->_raw->content;
}

sub _raw {
    my $self = shift;
    return $self->{raw};
}

sub headers {
    my $self = shift;
    my $raw  = $self->_raw;

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
    my $raw  = $self->_raw;

    # HTTP::Tiny returns a HashRef
    unless ( blessed($raw) ) {
        return $raw->{success};
    }

    # Furl::Response, HTTP::Response
    if ( $raw->can('is_success') ) {
        return $raw->isa('HTTP::Response')
            ? $raw->is_success && !$raw->header('X-Died')
            : $raw->is_success;
    }

    # Mojo::Transaction::HTTP
    return substr( $raw->res->code, 0, 1 ) == 2;
}

1;

