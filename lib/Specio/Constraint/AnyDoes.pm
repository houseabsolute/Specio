package Specio::Constraint::AnyDoes;

use strict;
use warnings;
use namespace::autoclean;

use B                  ();
use Devel::PartialDump ();
use Scalar::Util       ();
use Specio::Library::Builtins;

use Moose;

with 'Specio::Constraint::Role::DoesType';

my $Defined = t('Defined');
has '+parent' => (
    init_arg => undef,
    default  => sub { $Defined },
);

my $_inline_generator = sub {
    my $self = shift;
    my $val  = shift;

    return
          '( Scalar::Util::blessed('
        . $val
        . ') || ( '
        . " defined $val && ! ref $val ) ) && "
        . $val
        . q{->can('does')} . '&&'
        . $val
        . '->does('
        . B::perlstring( $self->role ) . ')';
};

has '+_inline_generator' => (
    init_arg => undef,
    default  => sub { $_inline_generator },
);

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A class for constraints which require a class name or an object that does a specific role

__END__

=head1 SYNOPSIS

  my $type = Specio::Constraint::AnyDoes->new(...);
  print $type->role();

=head1 DESCRIPTION

This is a specialized type constraint class for types which require a class
name or an object that does a specific role.

=head1 API

This class provides all of the same methods as L<Specio::Constraint::Simple>,
with a few differences:

=head2 Specio::Constraint::AnyDoes->new( ... )

The C<parent> parameter is ignored if it passed, as it is always set to the
C<Defined> type.

The C<inline_generator> and C<constraint> parameters are also ignored. This
class provides its own default inline generator subroutine reference.

This class overrides the C<message_generator> default if none is provided.

Finally, this class requires an additional parameter, C<role>. This must be a
single role name.

=head2 $any_isa->role()

Returns the role name passed to the constructor.

=head1 ROLES

This class does the L<Specio::Constraint::Role::DoesType>,
L<Specio::Constraint::Role::Interface>, L<Specio::Role::Inlinable>, and
L<MooseX::Clone> roles.
