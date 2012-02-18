package Type::Exporter;

use strict;
use warnings;

use Carp qw( croak );
use overload ();
use Params::Util qw( _STRING );
use Scalar::Util qw( blessed );
use Type::Registry qw( register types_for_package );

sub import {
    my $package = shift;

    my $caller = caller();

    my $provides = types_for_package($package);

    while ( my ( $name, $type ) = each %{$provides} ) {
        register( $caller, $name, $type );
    }

    my $caller_types = types_for_package($caller);

    _install_t_sub( $caller, $caller_types );
}

sub _install_t_sub {
    my $caller = shift;
    my $types  = shift;

    my $t = sub {
        croak 'The t() subroutine requires a single non-empty string argument'
            unless _STRINGLIKE( $_[0] );

        return $types->{ $_[0] };
    };

    {
        no strict 'refs';
        *{ $caller . '::t' } = $t;
    }

    return;
}

# XXX - this should be added to Params::Util
sub _STRINGLIKE ($) {
    return 1 if _STRING( $_[0] );

    return 1
        if blessed $_[0]
            && overload::Method( $_[0], q{""} )
            && length "$_[0]";

    return 0;
}

1;
