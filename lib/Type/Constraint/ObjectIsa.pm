package Type::Constraint::ObjectIsa;

use strict;
use warnings;
use namespace::autoclean;

use B                  ();
use Devel::PartialDump ();
use Scalar::Util       ();
use Type::Library::Builtins;

use Moose;

with 'Type::Constraint::Role::IsaType';

my $Object = t('Object');
has '+parent' => (
    init_arg => undef,
    default  => sub { $Object },
);

my $_inline_generator = sub {
    my $self = shift;
    my $val  = shift;

    return
          'Scalar::Util::blessed(' 
        . $val . ')' . ' && ' 
        . $val 
        . '->isa('
        . B::perlstring( $self->class ) . ')';
};

has '+_inline_generator' => (
    init_arg => undef,
    default  => sub { $_inline_generator },
);

has '+message_generator' => (
    default => sub { $_[0]->_default_message_generator() },
);

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A class for constraints which require an object that inherits from a specific class

__END__

=head1 SYNOPSIS

  my $type = Type::Constraint::ObjectIsa->new(...);
  print $type->class();

=head1 DESCRIPTION

This is a specialized type constraint class for types which require an object
that inherits from a specific class.

=head1 API

This class provides all of the same methods as L<Type::Constraint::Simple>,
with a few differences:

=head2 Type::Constraint::ObjectIsa->new( ... )

The C<parent> parameter is ignored if it passed, as it is always set to the
C<Defined> type.

The C<inline_generator> and C<constraint> parameters are also ignored. This
class provides its own default inline generator subroutine reference.

This class overrides the C<message_generator> default if none is provided.

Finally, this class requires an additional parameter, C<class>. This must be a
single class name.

=head2 $object_isa->class()

Returns the class name passed to the constructor.

=head1 ROLES

This class does the L<Type::Constraint::Role::IsaType>,
L<Type::Constraint::Role::Interface>, L<Type::Role::Inlinable>, and
L<MooseX::Clone> roles.
