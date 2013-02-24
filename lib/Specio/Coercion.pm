package Specio::Coercion;

use strict;
use warnings;

use Moose;

with 'MooseX::Clone', 'Specio::Role::Inlinable';

has from => (
    is       => 'ro',
    does     => 'Specio::Constraint::Role::Interface',
    required => 1,
);

has to => (
    is       => 'ro',
    does     => 'Specio::Constraint::Role::Interface',
    required => 1,
    weak_ref => 1,
);

has _coercion => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => '_has_coercion',
    init_arg  => 'coercion',
);

has _optimized_coercion => (
    is       => 'ro',
    isa      => 'CodeRef',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_optimized_coercion',
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $p = $class->$orig(@_);

    $p->{coercion} = delete $p->{using} if exists $p->{using};

    return $p;
};

sub BUILD {
    my $self = shift;

    die
        'A type coercion should have either a coercion or inline_generator parameter, not both'
        if $self->_has_coercion() && $self->_has_inline_generator();

    die
        'A type coercion must have either a coercion or inline_generator parameter'
        unless $self->_has_coercion() || $self->_has_inline_generator();

    return;
}

sub coerce {
    my $self  = shift;
    my $value = shift;

    return $self->_optimized_coercion()->($value);
}

sub inline_coercion {
    my $self = shift;

    return $self->_inline_generator()->( $self, @_ )
}

sub _build_optimized_coercion {
    my $self = shift;

    if ( $self->_has_inline_generator() ) {
        return $self->_generated_inline_sub();
    }
    else {
        return $self->_coercion();
    }
}

sub can_be_inlined {
    my $self = shift;

    return $self->_has_inline_generator() && $self->from()->can_be_inlined();
}

sub _build_description {
    my $self = shift;

    my $desc
        = 'coercion from '
        . ( $self->from()->name() // 'anon type' ) . ' to '
        . ( $self->to()->name()   // 'anon type' );

    $desc .= q{ } . $self->declared_at()->description();

    return $desc;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A class representing a coercion from one type to another

__END__

=head1 SYNOPSIS

  my $coercion = $type->coercion_from_type('Int');

  my $new_value = $coercion->coerce_value(42);

  if ( $coercion->can_be_inlined() ) {
      my $code = $coercion->inline_coercion('$_[0]');
  }

=head1 DESCRIPTION

This class represents a coercion from one type to another. Internally, a
coercion is a piece of code that takes a value of one type returns a new value
of a new type. For example, a coercion from c<Num> to C<Int> might round a
number to its nearest integer and return that integer.

Coercions can be implemented either as a simple subroutine reference or as an
inline generator subroutine. Using an inline generator is faster but more
complicated.

=head1 API

This class provides the following methods.

=head2 Specio::Coercion->new( ... )

This method creates a new coercion object. It accepts the following named
parameters:

=over 4

=item * from => $type

The type this coercion is from. The type must be an object which does the
L<Specio::Constraint::Role::Interface> interface.

This parameter is required.

=item * to => $type

The type this coercion is to. The type must be an object which does the
L<Specio::Constraint::Role::Interface> interface.

This parameter is required.

=item * coercion => sub { ... }

A subroutine reference implementing the coercion. It will be called as a
method on the object and passed a single argument, the value to coerce.

It should return the new value.

This parameter is mutually exclusive with C<inline_generator>.

Either this parameter or the C<inline_generator> parameter is required.

You can also pass this option with the key C<using> in the parameter list.

=item * inline_generator => sub { ... }

This should be a subroutine reference which returns a string containing a
single term. This code should I<not> end in a semicolon. This code should
implement the coercion.

The generator will be called as a method on the coercion with a single
argument. That argument is the name of the variable being coerced, something
like C<'$_[0]'> or C<'$var'>.

This parameter is mutually exclusive with C<coercion>.

Either this parameter or the C<coercion> parameter is required.

You can also pass this option with the key C<inline> in the parameter list.

=item * inline_environment => {}

This should be a hash reference of variable names (with sigils) and values for
that variable. The values should be I<references> to the values of the
variables.

This environment will be used when compiling the coercion as part of a
subroutine. The named variables will be captured as closures in the generated
subroutine, using L<Eval::Closure>.

It should be very rare to need to set this in the constructor. It's more
likely that a special coercion subclass would need to provide values that it
generates internally.

This parameter defaults to an empty hash reference.

=item * declared_at => $declared_at

This parameter must be a L<Specio::DeclaredAt> object.

This parameter is required.

=back

=head2 $coercion->from(), $coercion->to(), $coercion->declared_at()

These methods are all read-only attribute accessors for the corresponding
attribute.

=head2 $coercion->coerce($value)

Given a value of the right "from" type, returns a new value of the "to" type.

This method does not actually check that the types of given or return values.

=head2 $coercion->inline_coercion($var)

Given a variable name like C<'$_[0]'> this returns a string with code for the
coercion.

Note that this method will die if the coercion does not have an inline
generator.

=head2 $coercion->can_be_inlined()

This returns true if the coercion has an inline generator I<and> the
constraint it is from can be inlined. This exists primarily for the benefit of
the C<inline_coercion_and_check()> method for type constraint object.

=head1 ROLES

This class does the L<Specio::Role::Inlinable> and L<MooseX::Clone> roles.
