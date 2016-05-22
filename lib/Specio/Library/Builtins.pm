package Specio::Library::Builtins;

use strict;
use warnings;

our $VERSION = '0.14';

use parent 'Specio::Exporter';

use Class::Load ();
use List::Util 1.33 ();
use overload     ();
use re           ();
use Scalar::Util ();
use Specio::Constraint::Parameterizable;
use Specio::Declare;

declare(
    'Any',
    inline => sub {'1'}
);

declare(
    'Item',
    inline => sub {'1'}
);

declare(
    'Undef',
    parent => t('Item'),
    inline => sub {
        '!defined(' . $_[1] . ')';
    }
);

declare(
    'Defined',
    parent => t('Item'),
    inline => sub {
        'defined(' . $_[1] . ')';
    }
);

declare(
    'Bool',
    parent => t('Item'),
    inline => sub {
        return sprintf( <<'EOF', ( $_[1] ) x 8 );
(
    (
        !ref( %s )
        && (
               !defined( %s )
               || %s eq q{}
               || %s eq '1'
               || %s eq '0'
           )
    )
    ||
    (
        Scalar::Util::blessed( %s )
        && overload::Overloaded( %s )
        && defined overload::Method( %s, 'bool' )
    )
)
EOF
    }
);

declare(
    'Value',
    parent => t('Defined'),
    inline => sub {
        $_[0]->parent->inline_check( $_[1] ) . ' && !ref(' . $_[1] . ')';
    }
);

declare(
    'Ref',
    parent => t('Defined'),

    # no need to call parent - ref also checks for definedness
    inline => sub { 'ref(' . $_[1] . ')' }
);

declare(
    'Str',
    parent => t('Value'),
    inline => sub {
        return sprintf( <<'EOF', ( $_[1] ) x 7 );
(
    (
        defined( %s )
        && !ref( %s )
        && (
               ( ref( \%s ) eq 'SCALAR' )
               || ( ref( \( my $val = %s ) ) eq 'SCALAR' )
           )
    )
    ||
    (
        Scalar::Util::blessed( %s )
        && overload::Overloaded( %s )
        && defined overload::Method( %s, q{""} )
    )
)
EOF
    }
);

my $value_type = t('Value');
declare(
    'Num',
    parent => t('Str'),
    inline => sub {
        return sprintf( <<'EOF', ( $_[1] ) x 6 );
(
    (
        defined( %s )
        && !ref( %s )
        && (
               ( my $val = %s ) =~ /\A-?[0-9]+(?:\.[0-9]+)?\z/
           )
    )
    ||
    (
        Scalar::Util::blessed( %s )
        && overload::Overloaded( %s )
        && defined overload::Method( %s, '0+' )
    )
)
EOF
    }
);

declare(
    'Int',
    parent => t('Num'),
    inline => sub {
        return sprintf( <<'EOF', ( $_[1] ) x 7 )
(
    (
        defined( %s )
        && !ref( %s )
        && (
               ( my $val1 = %s ) =~ /\A-?[0-9]+\z/
           )
    )
    ||
    (
        Scalar::Util::blessed( %s )
        && overload::Overloaded( %s )
        && defined overload::Method( %s, '0+' )
        && ( my $val2 = %s + 0 ) =~ /\A-?[0-9]+\z/
    )
)
EOF
    }
);

declare(
    'CodeRef',
    parent => t('Ref'),
    inline => sub {
        return sprintf( <<'EOF', ( $_[1] ) x 4 );
(
    ref( %s ) eq 'CODE'
    ||
    (
        Scalar::Util::blessed( %s )
        && overload::Overloaded( %s )
        && defined overload::Method( %s, '&{}' )
    )
)
EOF
    }
);

declare(
    'RegexpRef',
    parent => t('Ref'),
    inline => sub {
        return sprintf( <<'EOF', ( $_[1] ) x 4 );
(
    re::is_regexp( %s )
    ||
    (
        Scalar::Util::blessed( %s )
        && overload::Overloaded( %s )
        && defined overload::Method( %s, 'qr' )
    )
)
EOF
    },
);

declare(
    'GlobRef',
    parent => t('Ref'),
    inline => sub {
        return sprintf( <<'EOF', ( $_[1] ) x 4 );
(
    ref( %s ) eq 'GLOB'
    ||
    (
        Scalar::Util::blessed( %s )
        && overload::Overloaded( %s )
        && defined overload::Method( %s, '*{}' )
    )
)
EOF
    }
);

# NOTE: scalar filehandles are GLOB refs, but a GLOB ref is not always a
# filehandle
declare(
    'FileHandle',
    parent => t('Ref'),
    inline => sub {
        return sprintf( <<'EOF', ( $_[1] ) x 7 );
(
    (
        ref( %s ) eq 'GLOB'
        && Scalar::Util::openhandle( %s )
    )
    ||
    (
        Scalar::Util::blessed( %s )
        &&
        (
            %s->isa('IO::Handle')
            ||
            (
                overload::Overloaded( %s )
                && defined overload::Method( %s, '*{}' )
                && Scalar::Util::openhandle( *{ %s } )
            )
        )
    )
)
EOF
    }
);

declare(
    'Object',
    parent => t('Ref'),
    inline => sub { 'Scalar::Util::blessed(' . $_[1] . ')' },
);

declare(
    'ClassName',
    parent => t('Str'),
    inline => sub {
        return sprintf( <<'EOF', $_[0]->parent->inline_check( $_[1] ), $_[1] )
(
    ( %s )
    && Class::Load::is_class_loaded( "%s" )
)
EOF
    },
);

{
    my $base_scalarref_check = sub {
        return sprintf( <<'EOF', ( $_[0] ) x 5 );
(
    (
        ref( %s ) eq 'SCALAR'
        || ref( %s ) eq 'REF'
    )
    ||
    (
        Scalar::Util::blessed( %s )
        && overload::Overloaded( %s )
        && defined overload::Method( %s, '${}' )
    )
)
EOF
    };

    declare(
        'ScalarRef',
        type_class => 'Specio::Constraint::Parameterizable',
        parent     => t('Ref'),
        inline     => sub { $base_scalarref_check->( $_[1] ) },
        parameterized_inline_generator => sub {
            my $self      = shift;
            my $parameter = shift;
            my $val       = shift;

            return sprintf(
                '( ( %s ) && ( %s ) )',
                $base_scalarref_check->($val),
                $parameter->inline_check( '${' . $val . '}' ),
            );
        }
    );
}

{
    my $base_arrayref_check = sub {
        return sprintf( <<'EOF', ( $_[0] ) x 4 );
(
    ref( %s ) eq 'ARRAY'
    ||
    (
        Scalar::Util::blessed( %s )
        && overload::Overloaded( %s )
        && defined overload::Method( %s, '@{}' )
    )
)
EOF
    };

    declare(
        'ArrayRef',
        type_class => 'Specio::Constraint::Parameterizable',
        parent     => t('Ref'),
        inline     => sub { $base_arrayref_check->( $_[1] ) },
        parameterized_inline_generator => sub {
            my $self      = shift;
            my $parameter = shift;
            my $val       = shift;

            return sprintf(
                '( ( %s ) && ( List::Util::all { %s } @{ %s } ) )',
                $base_arrayref_check->($val),
                $parameter->inline_check('$_'),
                $val,
            );
        }
    );
}

{
    my $base_hashref_check = sub {
        return sprintf( <<'EOF', ( $_[0] ) x 4 );
(
    ref( %s ) eq 'HASH'
    ||
    (
        Scalar::Util::blessed( %s )
        && overload::Overloaded( %s )
        && defined overload::Method( %s, '%%{}' )
    )
)
EOF
    };

    declare(
        'HashRef',
        type_class => 'Specio::Constraint::Parameterizable',
        parent     => t('Ref'),
        inline     => sub { $base_hashref_check->( $_[1] ) },
        parameterized_inline_generator => sub {
            my $self      = shift;
            my $parameter = shift;
            my $val       = shift;

            return sprintf(
                '( ( %s ) && ( List::Util::all { %s } values %%{ %s } ) )',
                $base_hashref_check->($val),
                $parameter->inline_check('$_'),
                $val,
            );
        }
    );
}

declare(
    'Maybe',
    type_class                     => 'Specio::Constraint::Parameterizable',
    parent                         => t('Item'),
    inline                         => sub {'1'},
    parameterized_inline_generator => sub {
        my $self      = shift;
        my $parameter = shift;
        my $val       = shift;

        return sprintf( <<'EOF', $val, $parameter->inline_check($val) )
( !defined( %s ) || ( %s ) )
EOF
    },
);

1;

# ABSTRACT: Implements type constraint objects for Perl's built-in types

__END__

=head1 DESCRIPTION

See the documentation in L<Specio> for a list of types that this library
implements.

This library uses L<Specio::Exporter> to export its types.

