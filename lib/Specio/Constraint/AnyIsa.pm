package Specio::Constraint::AnyIsa;

use strict;
use warnings;

our $VERSION = '0.13';

use B ();
use Role::Tiny::With;
use Scalar::Util ();
use Specio::Library::Builtins;
use Specio::OO;

use Specio::Constraint::Role::IsaType;
with 'Specio::Constraint::Role::IsaType';

{
    my $Defined = t('Defined');
    sub _build_parent {$Defined}
}

{
    my $_inline_generator = sub {
        my $self = shift;
        my $val  = shift;

        return
              '( Scalar::Util::blessed('
            . $val
            . ') || ( '
            . " defined $val && ! ref $val ) ) && "
            . $val
            . '->isa('
            . B::perlstring( $self->class ) . ')';
    };

    sub _build_inline_generator {$_inline_generator}
}

__PACKAGE__->_ooify();

1;

# ABSTRACT: A class for constraints which require a class name or an object that inherit from a specific class

__END__

=head1 SYNOPSIS

    my $type = Specio::Constraint::AnyIsa->new(...);
    print $type->class();

=head1 DESCRIPTION

This is a specialized type constraint class for types which require a class
name or an object that inherit from a specific class.

=head1 API

This class provides all of the same methods as L<Specio::Constraint::Simple>,
with a few differences:

=head2 Specio::Constraint::AnyIsa->new( ... )

The C<parent> parameter is ignored if it passed, as it is always set to the
C<Defined> type.

The C<inline_generator> and C<constraint> parameters are also ignored. This
class provides its own default inline generator subroutine reference.

This class overrides the C<message_generator> default if none is provided.

Finally, this class requires an additional parameter, C<class>. This must be a
single class name.

=head2 $any_isa->class()

Returns the class name passed to the constructor.

=head1 ROLES

This class does the L<Specio::Constraint::Role::IsaType>,
L<Specio::Constraint::Role::Interface>, and L<Specio::Role::Inlinable> roles.
