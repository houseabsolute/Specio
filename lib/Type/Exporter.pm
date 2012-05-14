package Type::Exporter;

use strict;
use warnings;

use Type::Helpers qw( install_t_sub );
use Type::Registry
    qw( exportable_types_for_package internal_types_for_package register );

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

# ABSTRACT: Base class for type libraries

__END__

=head1 SYNOPSIS

  package MyApp::Type::Library;

  use parent 'Type::Exporter';

  use Type::Declare;

  declare( ... );

  # more types here

  package MyApp::Foo;

  use MyApp::Type::Library

=head1 DESCRIPTION

Inheriting from this package makes your package a type exporter. By default,
types defined in a package are never visible outside of the package. When you
inherit from this package, all the types you define internally become
available via exports.

The exported types are available through the importing package's C<t()>
subroutine.

By default, types your package imports are not re-exported:

  package MyApp::Type::Library;

  use parent 'Type::Exporter';

  use Type::Declare;
  use Type::Library::Builtins;

In this case, the types provided by L<Type::Library::Builtins> are not
exported to packages which C<use MyApp::Type::Library>.

You can explicitly ask for types to be re-exported:

  package MyApp::Type::Library;

  use parent 'Type::Exporter';

  use Type::Declare;
  use Type::Library::Builtins -reexport;

In this case, packages which C<use MyApp::Type::Library> will get all the
types from L<Type::Library::Builtins> as well as any types defiend in
C<MyApp::Type::Library>.
