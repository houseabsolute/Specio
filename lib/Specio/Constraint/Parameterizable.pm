package Specio::Constraint::Parameterizable;

use strict;
use warnings;
use namespace::autoclean;

use MooseX::Params::Validate qw( validated_list );
use Specio::Constraint::Parameterized;
use Specio::DeclaredAt;

use Moose;

with 'Specio::Constraint::Role::Interface';

has _parameterized_constraint_generator => (
    is        => 'ro',
    isa       => 'CodeRef',
    init_arg  => 'parameterized_constraint_generator',
    predicate => '_has_parameterized_constraint_generator',
);

has _parameterized_inline_generator => (
    is        => 'ro',
    isa       => 'CodeRef',
    init_arg  => 'parameterized_inline_generator',
    predicate => '_has_parameterized_inline_generator',
);

sub BUILD {
    my $self = shift;

    if ( $self->_has_constraint() ) {
        die
            'A parameterizable constraint with a constraint parameter must also have a parameterized_constraint_generator'
            unless $self->_has_parameterized_constraint_generator();
    }

    if ( $self->_has_inline_generator() ) {
        die
            'A parameterizable constraint with an inline_generator parameter must also have a parameterized_inline_generator'
            unless $self->_has_parameterized_inline_generator();
    }

    return;
}

sub parameterize {
    my $self = shift;
    my ( $parameter, $declared_at ) = validated_list(
        \@_,
        of          => { does => 'Specio::Constraint::Role::Interface' },
        declared_at => {
            isa      => 'Specio::DeclaredAt',
            optional => 1,
        },
    );

    # This isn't a default so as to avoid generating it even when they
    # parameter is already set.
    $declared_at //= Specio::DeclaredAt->new_from_caller(1),

    my %p = (
        parent      => $self,
        parameter   => $parameter,
        declared_at => $declared_at,
    );

    if ( $self->_has_parameterized_constraint_generator() ) {
        $p{constraint}
            = $self->_parameterized_constraint_generator()->($parameter);
    }
    else {
        my $ig = $self->_parameterized_inline_generator();
        $p{inline_generator} = sub { $ig->( shift, $parameter, @_ ) };
    }

    return Specio::Constraint::Parameterized->new(%p);
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A class which represents parameterizable constraints

__END__

=head1 SYNOPSIS

  my $arrayref = t('ArrayRef');

  my $arrayref_of_int = $arrayref->parameterize( of => t('Int') );

=head1 DESCRIPTION

This class implements the API for parameterizable types like C<ArrayRef> and
C<Maybe>.

=head1 API

This class implements the same API as L<Specio::Constraint::Simple>, with a few
additions.

=head2 Specio::Constraint::Parameterizable->new(...)

This class's constructor accepts two additional parameters:

=over 4

=item * parameterized_constraint_generator

This is a subroutine that generates a new constraint subroutine when the type
is parameterized.

It will be called as a method on the type and will be passed a single
argument, the type object for the type parameter.

This parameter is mutually exclusive with the
C<parameterized_inline_generator> parameter.

=item * parameterized_inline_generator

This is a subroutine that generates a new inline generator subroutine when the
type is parameterized.

It will be called as a method on the L<Specio::Constraint::Parameterized> object
when that object needs to generate inline constraint. It will receive the type
parameter as the first argument and the variable name as a string as the
second.

This probably seems fairly confusing, so looking at the examples in the
L<Specio::Library::Builtins> code may be helpful.

This parameter is mutually exclusive with the
C<parameterized_inline_generator> parameter.

=back

=head2 $type->parameterize(...)

This method takes two arguments. The C<of> argument should be an object which
does the L<Specio::Constraint::Role::Interface> role, and is required.

The other argument, C<declared_at>, is optional. If it is not given, then a
new L<Specio::DeclaredAt> object is creating using a call stack depth of 1.

This method returns a new L<Specio::Constraint::Parameterized> object.

