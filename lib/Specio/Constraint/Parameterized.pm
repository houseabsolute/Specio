package Specio::Constraint::Parameterized;

use strict;
use warnings;
use namespace::autoclean;

use Moose;

with 'Specio::Constraint::Role::Interface';

has '+parent' => (
    isa      => 'Specio::Constraint::Parameterizable',
    required => 1,
);

has parameter => (
    is       => 'bare',
    does     => 'Specio::Constraint::Role::Interface',
    required => 1,
);

sub parameter { $_[0]->{parameter} }

sub can_be_inlined {
    my $self = shift;

    return $self->_has_inline_generator()
        && $self->parameter()->can_be_inlined();
}

# Moose compatibility methods - these exist as a temporary hack to make Specio
# work with Moose.

sub type_parameter {
    shift->parameter();
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A class which represents parameterized constraints

__END__

=head1 SYNOPSIS

  my $arrayref = t('ArrayRef');

  my $arrayref_of_int = $arrayref->parameterize( of => t('Int') );

  my $parent = $arrayref_of_int->parent(); # returns ArrayRef
  my $parameter = $arrayref_of_int->parameter(); # returns Int

=head1 DESCRIPTION

This class implements the API for parameterized types.

=head1 API

This class implements the same API as L<Specio::Constraint::Simple>, with a few
additions.

=head2 Specio::Constraint::Parameterized->new(...)

This class's constructor accepts two additional parameters:

=over 4

=item * parent

This should be the L<Specio::Constraint::Parameterizable> object from which this
object was created.

This parameter is required.

=item * parameter

This is the type parameter for the parameterized type. This must be an object
which does the L<Specio::Constraint::Role::Interface> role.

This parameter is required.

=back

=head2 $type->parameter()

Returns the type that was passed to the constructor.

