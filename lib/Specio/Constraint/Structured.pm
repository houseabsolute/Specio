package Specio::Constraint::Structured;

use strict;
use warnings;

our $VERSION = '0.50';

use Clone ();
use List::Util 1.33 qw( all );
use Role::Tiny::With;
use Specio::OO;
use Specio::TypeChecks qw( does_role );

use Specio::Constraint::Role::Interface;
with 'Specio::Constraint::Role::Interface';

{
    ## no critic (Subroutines::ProtectPrivateSubs)
    my $attrs = Clone::clone( Specio::Constraint::Role::Interface::_attrs() );
    ## use critic

    $attrs->{parent}{isa}      = 'Specio::Constraint::Structurable';
    $attrs->{parent}{required} = 1;

    $attrs->{parameters} = {
        isa      => 'HashRef',
        required => 1,
    };

    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    sub _attrs {
        return $attrs;
    }
}

sub can_be_inlined {
    my $self = shift;
    return $self->_has_inline_generator;
}

__PACKAGE__->_ooify;

1;

# ABSTRACT: A class which represents structured constraints

__END__

=pod

=for Pod::Coverage can_be_inlined type_parameter

=head1 SYNOPSIS

    my $tuple = t('Tuple');

    my $tuple_of_str_int = $tuple->parameterize( of => [ t('Str'), t('Int') ] );

    my $parent = $tuple_of_str_int->parent; # returns Tuple
    my $parameters = $arrayref_of_int->parameters; # returns { of => [ t('Str'), t('Int') ] }

=head1 DESCRIPTION

This class implements the API for structured types.

=head1 API

This class implements the same API as L<Specio::Constraint::Simple>, with a few
additions.

=head2 Specio::Constraint::Structured->new(...)

This class's constructor accepts two additional parameters:

=over 4

=item * parent

This should be the L<Specio::Constraint::Structurable> object from which this
object was created.

This parameter is required.

=item * parameters

This is the hashref of parameters for the structured type. These are the
parameters returned by the C<Structurable> type's
C<parameterization_args_builder>. The exact form of this hashref will vary for
each structured type.

This parameter is required.

=back

=head2 $type->parameters

Returns the hashref that was passed to the constructor.

=cut
