package Type::Declare;

use strict;
use warnings;

use Carp;
use Exporter ();
use Scalar::Util qw( blessed );
use Type::Constraint::Simple;
use Type::Constraint::Undeclared;

my %global;
sub import {
    my $package = shift;

    my $caller = caller();

    for my $sub (qw( declare anon parent where message inline_with )) {
        my $internal_sub = $package->can($sub);
        no strict 'refs';
        *{ $caller . '::' . $sub } = $internal_sub;
    }

    my %registry;

    for my $name (@_) {
        $registry{$name} = Type::Constraint::Undeclared->new( name => $name );
    }

    $global{$caller} = \%registry;

    my $t = sub {
        Carp::croak 't() must be called with a single argument' unless @_;
        Carp::croak "No such type: $_[0]" unless exists $registry{ $_[0] };
        return $registry{ $_[0] };
    };

    {
        no strict 'refs';
        *{ $caller . '::t' } = $t;

        @{ $caller . '::ISA' } = 'Exporter';
        @{ $caller . '::EXPORT' } = 't';
    }

    return;
}

sub declare {
    my $name = shift->name();
    my %p    = (
        name => $name,
        map { @{$_} } @_,
    );

    my $tc = Type::Constraint::Simple->new(
        %p,
        declared_at => _declared_at(),
    );

    $global{ caller() }{$name} = $tc;

    return;
}

sub anon {
    my %p = map { @{$_} } @_;

    return Type::Constraint::Simple->new(
        %p,
        declared_at => _declared_at(),
    );
}

sub _declared_at {
    my ( $package, $filename, $line, $sub ) = caller(2);

    return {
        package  => $package,
        filename => $filename,
        line     => $line,
        sub      => $sub,
    };
}

sub parent ($) {
    return [ parent => $_[0] ];
}

sub where (&) {
    return [ constraint => $_[0] ];
}

sub message (&) {
    return [ message_generator => $_[0] ];
}

sub inline_with (&) {
    return [ inline_generator => $_[0] ];
}

1;
