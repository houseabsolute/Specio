package Type::Constraint::AnyCan;

use strict;
use warnings;
use namespace::autoclean;

use B ();
use Scalar::Util;
use Type::Library::Builtins;

use Moose;

with 'Type::Constraint::Role::CanType';

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
        . " defined $val && ! ref $val ) )"
        . ' && List::MoreUtils::all { '
        . $val
        . '->can($_) } ' . '( '
        . ( join ', ', map { B::perlstring($_) } @{ $self->methods() } )
        . ')';
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

# ABSTRACT: A class for constraints which require a class name or object with a set of methods

__END__

=head1 SYNOPSIS

  my $type = Type::Constraint::AnyCan->new(...);
  print $_, "\n" for @{ $type->methods() };

=head1 DESCRIPTION

This is a specialized type constraint class for types which require a class
name or object with a defined set of methods.

=head1 API

This class provides all of the same methods as L<Type::Constraint::Simple>,
with a few differences:

=head2 Type::Constraint::AnyCan->new( ... )

The C<parent> parameter is ignored if it passed, as it is always set to the
C<Defined> type.

The C<inline_generator> and C<constraint> parameters are also ignored. This
class provides its own default inline generator subroutine reference.

This class overrides the C<message_generator> default if none is provided.

Finally, this class requires an additional parameter, C<methods>. This must be
an array reference of method names which the constraint requires. You can also
pass a single string and it will be converted to an array reference
internally.

=head2 $any_can->methods()

Returns an array reference containing the methods this constraint requires.

=head1 ROLES

This class does the L<Type::Constraint::Role::CanType>,
L<Type::Constraint::Role::Interface>, L<Type::Role::Inlinable>, and
L<MooseX::Clone> roles.
