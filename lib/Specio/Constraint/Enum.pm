package Specio::Constraint::Enum;

use strict;
use warnings;

our $VERSION = '0.15';

use B ();
use Role::Tiny::With;
use Scalar::Util qw( refaddr );
use Specio::Library::Builtins;
use Specio::OO;
use Storable qw( dclone );

use Specio::Constraint::Role::Interface;
with 'Specio::Constraint::Role::Interface';

{
    ## no critic (Subroutines::ProtectPrivateSubs)
    my $attrs = dclone( Specio::Constraint::Role::Interface::_attrs() );
    ## use critic

    for my $name (qw( parent _inline_generator )) {
        $attrs->{$name}{init_arg} = undef;
        $attrs->{$name}{builder}
            = $name =~ /^_/ ? '_build' . $name : '_build_' . $name;
    }

    $attrs->{values} = {
        isa      => 'ArrayRef',
        required => 1,
    };

    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    sub _attrs {
        return $attrs;
    }
}

{
    my $Str = t('Str');
    sub _build_parent {$Str}
}

{
    my $_inline_generator = sub {
        my $self = shift;
        my $val  = shift;

        return sprintf( <<'EOF', $val, $self->_env_var_name, $val );
( !ref( %s ) && $%s{ %s } )
EOF
    };

    sub _build_inline_generator {$_inline_generator}
}

sub _build_inline_environment {
    my $self = shift;

    my %values = map { $_ => 1 } @{ $self->values() };

    return { '%' . $self->_env_var_name => \%values };
}

sub _env_var_name {
    my $self = shift;

    return '_Specio_Constraint_Enum_' . refaddr($self);
}

__PACKAGE__->_ooify();

1;

# ABSTRACT: A class for constraints which require a string matching one of a set of values

__END__

=head1 SYNOPSIS

    my $type = Specio::Constraint::Enum->new(...);
    print $_, "\n" for @{ $type->values() };

=head1 DESCRIPTION

This is a specialized type constraint class for types which require a string
that matches one of a list of values.

=head1 API

This class provides all of the same methods as L<Specio::Constraint::Simple>,
with a few differences:

=head2 Specio::Constraint::Enum->new( ... )

The C<parent> parameter is ignored if it passed, as it is always set to the
C<Str> type.

The C<inline_generator> and C<constraint> parameters are also ignored. This
class provides its own default inline generator subroutine reference.

Finally, this class requires an additional parameter, C<values>. This must be a
a list of valid strings for the type.

=head2 $enum->values()

Returns an array reference of valid values for the type.

=head1 ROLES

This class does the L<Specio::Constraint::Role::Interface> and
L<Specio::Role::Inlinable> roles.
