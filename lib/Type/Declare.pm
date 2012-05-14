package Type::Declare;

use strict;
use warnings;

use parent 'Exporter';

use Carp qw( croak );
use Params::Util qw( _CODELIKE );
use Type::Coercion;
use Type::Constraint::Simple;
use Type::DeclaredAt;
use Type::Helpers qw( install_t_sub _INSTANCEDOES _STRINGLIKE );
use Type::Registry qw( internal_types_for_package register );

our @EXPORT = qw(
    anon
    any_can_type
    any_isa_type
    coerce
    declare
    enum
    object_can_type
    object_isa_type
);

sub import {
    my $package = shift;

    my $caller = caller();

    $package->export_to_level( 1, $package, @_ );

    install_t_sub(
        $caller,
        internal_types_for_package($caller)
    );

    return;
}

sub declare {
    my $name = _STRINGLIKE(shift)
        or croak 'You must provide a name for declared types';
    my %p = @_;

    my $tc = _make_tc( name => $name, %p );

    register( scalar caller(), $name, $tc, 'exportable' );

    return $tc;
}

sub anon {
    return _make_tc(@_);
}

sub enum {
    my $name;
    $name = shift if @_ % 2;
    my %p = @_;

    require Type::Constraint::Enum;

    my $tc = _make_tc(
        ( defined $name ? ( name => $name ) : () ),
        values     => $p{values},
        type_class => 'Type::Constraint::Enum',
    );

    register( scalar caller(), $name, $tc, 'exportable' )
        if defined $name;

    return $tc;
}

sub object_can_type {
    my $name;
    $name = shift if @_ % 2;
    my %p = @_;

    # This cannot be loaded earlier, since it loads Type::Library::Builtins,
    # which in turn wants to load Type::Declare (the current module).
    require Type::Constraint::ObjectCan;

    my $tc = _make_tc(
        ( defined $name ? ( name => $name ) : () ),
        methods    => $p{methods},
        type_class => 'Type::Constraint::ObjectCan',
    );

    register( scalar caller(), $name, $tc, 'exportable' )
        if defined $name;

    return $tc;
}

sub object_isa_type {
    my $name = shift;
    my $isa = shift || $name;

    require Type::Constraint::ObjectIsa;

    my $tc = _make_tc(
        name       => $name,
        class      => $isa,
        type_class => 'Type::Constraint::ObjectIsa',
    );

    register( scalar caller(), $name, $tc, 'exportable' );

    return $tc;
}

sub any_can_type {
    my $name;
    $name = shift if @_ % 2;
    my %p = @_;

    # This cannot be loaded earlier, since it loads Type::Library::Builtins,
    # which in turn wants to load Type::Declare (the current module).
    require Type::Constraint::AnyCan;

    my $tc = _make_tc(
        ( defined $name ? ( name => $name ) : () ),
        methods    => $p{methods},
        type_class => 'Type::Constraint::AnyCan',
    );

    register( scalar caller(), $name, $tc, 'exportable' )
        if defined $name;

    return $tc;
}

sub any_isa_type {
    my $name = shift;
    my $isa = shift || $name;

    require Type::Constraint::AnyIsa;

    my $tc = _make_tc(
        name       => $name,
        class      => $isa,
        type_class => 'Type::Constraint::AnyIsa',
    );

    register( scalar caller(), $name, $tc, 'exportable' );

    return $tc;
}

sub _make_tc {
    my %p = @_;

    my $class = delete $p{type_class} || 'Type::Constraint::Simple';

    return $class->new(
        %p,
        declared_at => Type::DeclaredAt->new_from_caller(2),
    );
}

sub coerce {
    my $to = shift;

    return $to->add_coercion(
        Type::Coercion->new(
            to          => $to, @_,
            declared_at => Type::DeclaredAt->new_from_caller(1),
        )
    );
}

1;

# ABSTRACT: Type declaration subroutines

__END__

=head1 SYNOPSIS

  package MyApp::Type::Library;

  use parent 'Type::Exporter';

  use Type::Declare;
  use Type::Library::Builtins;

  declare(
      'Foo',
      parent => t('Str'),
      where  => sub { $_[0] =~ /foo/i },
  );

  my $even = anon(
      parent => t('Int'),
      inline => sub {
          my $type      = shift;
          my $value_var = shift;

          return $value_var . ' % 2 == 0';
      },
  );

  coerce(
      'ArrayRef',
      from  => t('Foo'),
      using => sub { [ $_[0] ] },
  );

  coerce(
      $even,
      from  => t('Int'),
      using => sub { $_[0] % 2 ? $_[0] + 1 : $_[0] },
  );

  # Type name is DateTime
  any_isa_type('DateTime');

  # Type name is DateTimeObject
  object_isa_type( 'DateTimeObject', 'DateTime' );

  any_can_type(
      'Duck',
      methods => [ 'duck_walk', 'quack' ],
  );

  object_can_type(
      'DuckObject',
      methods => [ 'duck_walk', 'quack' ],
  );

  enum(
      'Colors',
      [qw( blue green red )],
  );

=head1 DESCRIPTION

This package exports a set of type declaration helpers. Importing this package
also causes it to create a C<t()> subroutine the caller.

=head1 SUBROUTINES

This module exports the following subroutines.

=head2 t('name')

This subroutine lets you access any types you have declared so far, as well as
any types you imported from another type library.

If you pass an unknown name, it throws an exception.

=head2 declare(...)

This subroutine declares a named type. The first argument is the type name,
followed by a set of key/value parameters:

=over 4

=item * parent => $type

The parent should be another type object. Specifically, it can be anything
which does the L<Type::Constraint::Role::Interface> role. The parent can be a
named or anonymous type.

=item * where => sub { ... }

This is a subroutine which defines the type constraint. It will be passed a
single argument, the value to check, and it should return true or false to
indicate whether or not the value is valid for the type.

This parameter is mutually exclusive with the C<inline> parameter.

=item * inline => sub { ... }

This is a subroutine that is called to generate inline code to validate the
type. Inlining can be I<much> faster than simply providing a subroutine with
the C<where> parameter, but is often more complicated to get right.

The inline generator is called as a method on the type with one argument. This
argument is a I<string> containing the variable name to use in the generated
code. Typically this is something like C<'$_[0]'> or C<'$value'>.

The inline generator subroutine should return a I<string> of code representing
a single term, and it I<should not> be terminated with a semicolon. This
allows the inlined code to be safely included in an C<if> statement, for
example. You can use C<do { }> blocks and ternaries to get everything into one
term. This single term should evaluate to true or false.

The inline generator is expected to include code to implement both the current
type and all its parents. Typically, the easiest way to do this is to write a
subroutine something like this:

  sub {
      my $self = shift;
      my $var  = shift;

      return $_[0]->parent()->inline_check( $_[1] )
          . ' and more checking code goes here';
  }

This parameter is mutually exclusive with the C<where> parameter.

=item * message_generator => sub { ... }

A subroutine to generate an error message when the type check fails. The
default message says something like "Validation failed for type named Int
declared in package Type::Library::Builtins
(.../Type/blib/lib/Type/Library/Builtins.pm) at line 147 in sub named (eval)
with value 1.1".

You can override this to provide something more specific about the way the
type failed.

The subroutine you provide will be called as a method on the type with two
arguments. The first is the description of the type (the bit in the message
above that starts with "type named Int ..." and ends with "... in sub named
(eval)". This description says what the thing is and where it was defined.

The second argument is the value that failed the type check, after any
coercions that might have been applied.

=back

=head2 anon(...)

This subroutine declares an anonymous type. It is identical to C<declare()>
except that it expects a list of key/value parameters without a type name as
the first parameter.

=head2 coerce(...)

This declares a coercion from one type to another. The first argument should
be an object which does the L<Type::Constraint::Role::Interface> role. This
can be either a named or anonymous type. This type is the type that the
coercion is I<to>.

The remaining arguments are key/value parameters:

=over 4

=item * from => $type

This must be an object which does the L<Type::Constraint::Role::Interface>
role. This is type that we are coercing I<from>. Again, this can be either a
named or anonymous type.

=item * using => sub { ... }

This is a subroutine which defines the type coercion. It will be passed a
single argument, the value coerce. It should return a new value of the type
this coercion is to.

This parameter is mutually exclusive with the C<inline> parameter.

=item * inline => sub { ... }

This is a subroutine that is called to generate inline code to perform the
coercion.

The inline generator is called as a method on the type with one argument. This
argument is a I<string> containing the variable name to use in the generated
code. Typically this is something like C<'$_[0]'> or C<'$value'>.

The inline generator subroutine should return a I<string> of code representing
a single term, and it I<should not> be terminated with a semicolon. This
allows the inlined code to be safely included in an C<if> statement, for
example. You can use C<do { }> blocks and ternaries to get everything into one
term. This single term should evaluate to the new value.

=back
