use strict;
use warnings;
package UserAgent::Compat;

sub new {
    my $class = shift;
    my %args  = @_;

    die 'You must provide a user_agent arg' unless $args{user_agent};
    return bless { user_agent => $args{user_agent} }, $class;
}

sub delete {
    my $self = shift;
    return $self->_res('delete', @_ );
}

sub get {
    my $self = shift;
    return $self->_res('get', @_ );
}

sub head {
    my $self = shift;
    return $self->_res('head', @_ );
}

sub post {
    my $self = shift;
    return $self->_res('post', @_ );
}

sub put {
    my $self = shift;
    return $self->_res('put', @_ );
}

sub _res {
    my $self = shift;
    my $method = shift;
    my $res = $self->{user_agent}->$method( @_ );
    return UserAgent::Compat::Response->new( $res );
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
    my $res = shift;

    die 'You must provide a response object' unless $res;
    return bless { raw => $res }, $class;
}

sub headers {
    my $self = shift;
    my $raw = $self->{raw};

    # HTTP::Tiny returns a HashRef
    unless ( blessed( $raw ) ) {
        return $raw->{headers};
    }

    if ( $raw->isa('Mojo::Transaction::HTTP' )) {
        return $raw->res->headers->to_hash;
    }

    if ( $raw->can('headers') ) {
        return [$raw->headers->flatten];
    }
}

sub is_success {
    my $self = shift;
    my $raw = $self->{raw};

    # HTTP::Tiny returns a HashRef
    unless ( blessed( $raw ) ) {
        return $raw->{success};
    }

    # Furl::Response, HTTP::Response
    if ( $raw->can('is_success') ) {
        return $raw->is_success && !$raw->header('X-Died');
    }

    # Mojo::Transaction::HTTP
    return substr($raw->res->code, 0, 1) == 2;
}

1;


