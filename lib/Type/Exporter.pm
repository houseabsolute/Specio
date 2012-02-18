package Type::Exporter;

use strict;
use warnings;

use Carp qw( croak );
use overload ();
use Params::Util qw( _STRING );
use Scalar::Util qw( blessed );
use Type::Registry qw( register );

sub import {
    my $package  = shift;
    my $reexport = shift;

    my $caller = caller();

    my $exported = Type::Registry::exportable_types_for_package($package);

    while ( my ( $name, $type ) = each %{$exported} ) {
        register( $caller, $name, $type->clone(), $reexport );
    }

    _install_t_sub(
        $caller,
        Type::Registry::internal_types_for_package($caller),
    );
}

sub _install_t_sub {
    my $caller = shift;
    my $types  = shift;

    my $t = sub {
        croak 'The t() subroutine requires a single non-empty string argument'
            unless _STRINGLIKE( $_[0] );

        croak "There is no type named $_[0] available for the $caller package"
            unless exists $types->{ $_[0] };

        return $types->{ $_[0] };
    };

    {
        no strict 'refs';
        no warnings 'redefine';
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
