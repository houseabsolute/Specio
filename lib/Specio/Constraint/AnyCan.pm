package Specio::Constraint::AnyCan;

use strict;
use warnings;

our $VERSION = '0.29';

use B ();
use List::Util 1.33 ();
use Role::Tiny::With;
use Scalar::Util ();
use Specio::Library::Builtins;
use Specio::OO;

use Specio::Constraint::Role::CanType;
with 'Specio::Constraint::Role::CanType';

{
    my $Defined = t('Defined');
    sub _build_parent {$Defined}
}

{
    my $_inline_generator = sub {
        my $self = shift;
        my $val  = shift;

        my $methods = join ', ',
            map { B::perlstring($_) } @{ $self->methods };
        return sprintf( <<'EOF', ($val) x 3, $methods );
(
    (
        Scalar::Util::blessed( %s )
        ||
        (
            !ref( %s )
        )
    )
    &&
    List::Util::all { %s->can($_) } %s
)
EOF
    };

    sub _build_inline_generator {$_inline_generator}
}

__PACKAGE__->_ooify;

1;

# ABSTRACT: A class for constraints which require a class name or object with a set of methods

__END__

=head1 SYNOPSIS

    my $type = Specio::Constraint::AnyCan->new(...);
    print $_, "\n" for @{ $type->methods };

=head1 DESCRIPTION

This is a specialized type constraint class for types which require a class
name or object with a defined set of methods.

=head1 API

This class provides all of the same methods as L<Specio::Constraint::Simple>,
with a few differences:

=head2 Specio::Constraint::AnyCan->new( ... )

The C<parent> parameter is ignored if it passed, as it is always set to the
C<Defined> type.

The C<inline_generator> and C<constraint> parameters are also ignored. This
class provides its own default inline generator subroutine reference.

This class overrides the C<message_generator> default if none is provided.

Finally, this class requires an additional parameter, C<methods>. This must be
an array reference of method names which the constraint requires. You can also
pass a single string and it will be converted to an array reference
internally.

=head2 $any_can->methods

Returns an array reference containing the methods this constraint requires.

=head1 ROLES

This class does the L<Specio::Constraint::Role::IsaType>,
L<Specio::Constraint::Role::Interface>, and L<Specio::Role::Inlinable> roles.
