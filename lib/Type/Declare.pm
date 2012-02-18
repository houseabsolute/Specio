package Type::Declare;

use strict;
use warnings;

use parent 'Exporter';

use Carp;
use Scalar::Util qw( blessed );
use Type::Constraint::Simple;
use Type::Constraint::Undeclared;
use Type::Exporter ();
use Type::Registry qw( register types_for_package );

our @EXPORT = qw( declare anon parent where message inline_with );

sub import {
    my $package = shift;
    my %p       = @_;

    my $caller = caller();

    for my $name ( @{ $p{-declare} || [] } ) {
        register(
            $caller,
            $name,
            Type::Constraint::Undeclared->new( name => $name ),
        );
    }

    $package->export_to_level( 1, $package, @{ $p{-import} || [] } );

    Type::Exporter::_install_t_sub( $caller, types_for_package($caller) );

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

    register( scalar caller(), $name, $tc );

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
