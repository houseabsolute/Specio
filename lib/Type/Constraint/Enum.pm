package Type::Constraint::Enum;

use strict;
use warnings;
use namespace::autoclean;

use B ();
use Type::Library::Builtins;

use Moose;

with 'Type::Constraint::Role::Interface';

my $Str = t('Str');
has '+parent' => (
    init_arg => undef,
    default  => sub { $Str },
);

has values => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

my $_inline_generator = sub {
    my $self = shift;
    my $val  = shift;

    return
          'defined(' 
        . $val . ') '
        . '&& !ref('
        . $val . ') '
        . '&& $_Type_Constraint_Enum_enum_values{'
        . $val . '}';
};

has '+_inline_generator' => (
    init_arg => undef,
    default  => sub { $_inline_generator },
);

sub _build_inline_environment {
    my $self = shift;

    my %values = map { $_ => 1 } @{ $self->values() };

    return { '%_Type_Constraint_Enum_enum_values' => \%values };
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A class for constraints which require a string matching one of a set of values

__END__

=head1 SYNOPSIS

  my $type = Type::Constraint::Enum->new(...);
  print $_, "\n" for @{ $type->values() };

=head1 DESCRIPTION

This is a specialized type constraint class for types which require a string
that matches one of a list of values.

=head1 API

This class provides all of the same methods as L<Type::Constraint::Simple>,
with a few differences:

=head2 Type::Constraint::Enum->new( ... )

The C<parent> parameter is ignored if it passed, as it is always set to the
C<Str> type.

The C<inline_generator> and C<constraint> parameters are also ignored. This
class provides its own default inline generator subroutine reference.

Finally, this class requires an additional parameter, C<values>. This must be a
a list of valid strings for the type.

=head2 $enum->values()

Returns an array reference of valid values for the type.

=head1 ROLES

This class does the L<Type::Constraint::Role::Interface>,
L<Type::Role::Inlinable>, and L<MooseX::Clone> roles.
