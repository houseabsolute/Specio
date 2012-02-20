package Type::Exporter;

use strict;
use warnings;

use Type::Helpers qw( install_t_sub );
use Type::Registry qw( exportable_types_for_package internal_types_for_package register );

sub import {
    my $package  = shift;
    my $reexport = shift;

    my $caller = caller();

    my $exported = exportable_types_for_package($package);

    while ( my ( $name, $type ) = each %{$exported} ) {
        register( $caller, $name, $type->clone(), $reexport );
    }

    install_t_sub(
        $caller,
        internal_types_for_package($caller),
    );
}

1;
