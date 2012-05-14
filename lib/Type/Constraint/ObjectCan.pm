package Type::Constraint::ObjectCan;

use strict;
use warnings;
use namespace::autoclean;

use B ();
use Scalar::Util;
use Type::Library::Builtins;

use Moose;

with 'Type::Constraint::Role::CanType';

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
        . $val . ')'
        . ' && List::MoreUtils::all { '
        . $val
        . '->can($_) } ' . '( '
        . ( join ', ', map { B::perlstring($_) } @{ $self->methods() } ) . ')';
};

has '+inline_generator' => (
    init_arg => undef,
    default  => sub { $_inline_generator },
);

has '+message_generator' => (
    default => sub { $_[0]->_default_message_generator() },
);

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A class for constraints which require an object with a set of methods

__END__

=head1 SYNOPSIS

  my $type = Type::Constraint::ObjectCan->new(...);
  print $_, "\n" for @{ $type->methods() };

=head1 DESCRIPTION

This is a specialized type constraint class for types which require an object
with a defined set of methods.

=head1 API

This class provides all of the same methods as L<Type::Constraint::Simple>,
with a few differences:

=head2 Type::Constraint::ObjectCan->new( ... )

The C<parent> parameter is ignored if it passed, as it is always set to the
C<Object> type.

The C<inline_generator> and C<constraint> parameters are also ignored. This
class provides its own default inline generator subroutine reference.

This class overrides the C<message_generator> default if none is provided.

Finally, this class requires an additional parameter, C<methods>. This must be
an array reference of method names which the constraint requires. You can also
pass a single string and it will be converted to an array reference
internally.

=head2 $object_can->methods()

Returns an array reference containing the methods this constraint requires.

=head1 ROLES

This class does the L<Type::Constraint::Role::CanType>,
L<Type::Constraint::Role::Interface>, L<Type::Role::Inlinable>, and
L<MooseX::Clone> roles.
