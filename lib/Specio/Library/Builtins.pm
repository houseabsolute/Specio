package Specio::Library::Builtins;

use strict;
use warnings;

use parent 'Specio::Exporter';

use Class::Load qw( is_class_loaded );
use List::Util 1.33 ();
use overload ();
use re qw( is_regexp );

our $VERSION = '0.12';

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
        'Scalar::Util::blessed('
            . $_[1] . ') ? '
            . ' overload::Overloaded('
            . $_[1]
            . ') && defined overload::Method('
            . $_[1]
            . ', "bool")' . ' : ('
            . '!defined('
            . $_[1] . ') ' . '|| '
            . $_[1]
            . ' eq "" ' . '|| ('
            . $_[1]
            . '."") eq "1" ' . '|| ('
            . $_[1]
            . '."") eq "0"' . ')';
    }
);

declare(
    'Value',
    parent => t('Defined'),
    inline => sub {
        $_[0]->parent()->inline_check( $_[1] ) . ' && !ref(' . $_[1] . ')';
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
        'Scalar::Util::blessed('
            . $_[1] . ')'
            . ' && overload::Overloaded('
            . $_[1]
            . ') && defined overload::Method('
            . $_[1]
            . ', q{""})'
            . ' ? 1 : '
            . $_[0]->parent()->inline_check( $_[1] ) . ' && '
            . '( ref(\\'
            . $_[1]
            . ') eq "SCALAR"'
            . ' || ref(\\(my $val = '
            . $_[1]
            . ')) eq "SCALAR"' . ')';
    }
);

my $value_type = t('Value');
declare(
    'Num',
    parent => t('Str'),
    inline => sub {
        'Scalar::Util::blessed('
            . $_[1] . ') ? '
            . ' overload::Overloaded('
            . $_[1]
            . ') && defined overload::Method('
            . $_[1]
            . ', "0+")' . ' : ( '
            . $value_type->inline_check( $_[1] )
            . ' && ( my $val = '
            . $_[1]
            . ' ) =~ /\\A-?[0-9]+(?:\\.[0-9]+)?\\z/ )';
    }
);

declare(
    'Int',
    parent => t('Num'),
    inline => sub {
        'Scalar::Util::blessed('
            . $_[1] . ') ? '
            . ' overload::Overloaded('
            . $_[1]
            . ') && defined overload::Method('
            . $_[1]
            . ', "0+") && '
            . ' ( ( my $val1 = '
            . $_[1]
            . ' + 0 ) =~ /\A-?[0-9]+\z/ )'
            . ' : ( ( '
            . $value_type->inline_check( $_[1] )
            . ') && ( my $val2 = '
            . $_[1]
            . ' ) =~ /\A-?[0-9]+\z/ )';
    }
);

declare(
    'CodeRef',
    parent => t('Ref'),
    inline => sub {
        'Scalar::Util::blessed('
            . $_[1] . ') ? '
            . ' overload::Overloaded('
            . $_[1]
            . ') && defined overload::Method('
            . $_[1]
            . ', "&{}") '
            . ' : ref('
            . $_[1]
            . ') eq "CODE"';
    },
);

declare(
    'RegexpRef',
    parent => t('Ref'),
    inline => sub {
        '( Scalar::Util::blessed('
            . $_[1] . ') && '
            . ' overload::Overloaded('
            . $_[1]
            . ') && defined overload::Method('
            . $_[1]
            . ', "qr") ) || '
            . 're::is_regexp('
            . $_[1] . ')';
    },
);

declare(
    'GlobRef',
    parent => t('Ref'),
    inline => sub {
        'Scalar::Util::blessed('
            . $_[1] . ') ? '
            . 'overload::Overloaded('
            . $_[1]
            . ') && defined overload::Method('
            . $_[1]
            . ', "*{}") '
            . ' : ( ref('
            . $_[1]
            . ') eq "GLOB" )';
    },
);

# NOTE: scalar filehandles are GLOB refs, but a GLOB ref is not always a
# filehandle
declare(
    'FileHandle',
    parent => t('Ref'),
    inline => sub {
        'Scalar::Util::blessed('
            . $_[1] . ') ? '
            . $_[1]
            . '->isa("IO::Handle") || '
            . '( overload::Overloaded('
            . $_[1]
            . ') && defined overload::Method('
            . $_[1]
            . ', "*{}") '
            . '&& Scalar::Util::openhandle( *{'
            . $_[1] . '} ) )'
            . ' : ref('
            . $_[1]
            . ') eq "GLOB" '
            . '&& Scalar::Util::openhandle('
            . $_[1] . ')';
    },
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
        '('
            . $_[0]->parent()->inline_check( $_[1] ) . ')'
            . ' && ( defined( '
            . $_[1]
            . ') && Class::Load::is_class_loaded("'
            . $_[1] . '") )';
    },
);

declare(
    'ScalarRef',
    type_class => 'Specio::Constraint::Parameterizable',
    parent     => t('Ref'),
    inline     => sub {
        'Scalar::Util::blessed('
            . $_[1] . ') ? '
            . 'overload::Overloaded('
            . $_[1]
            . ') && defined overload::Method('
            . $_[1]
            . ', "\\${}") '
            . ' : ref( '
            . $_[1]
            . q{ ) eq 'SCALAR' || ref( }
            . $_[1]
            . q{ ) eq 'REF' };
    },
    parameterized_inline_generator => sub {
        my $self      = shift;
        my $parameter = shift;
        my $val       = shift;

        return
              'Scalar::Util::blessed('
            . $val . ') ? '
            . 'overload::Overloaded('
            . $val
            . ') && defined overload::Method('
            . $val
            . ', "\\${}") ' . ' && '
            . $parameter->inline_check( '${ ( ' . $val . ' ) }' )
            . ' : ( ref( '
            . $val
            . q{ ) eq 'SCALAR' || ref( }
            . $val
            . q{ ) eq 'REF' ) } . ' && '
            . $parameter->inline_check( '${ ( ' . $val . ' ) }' );
    },
);

declare(
    'ArrayRef',
    type_class => 'Specio::Constraint::Parameterizable',
    parent     => t('Ref'),
    inline     => sub {
        'Scalar::Util::blessed('
            . $_[1] . ') ? '
            . 'overload::Overloaded('
            . $_[1]
            . ') && defined overload::Method('
            . $_[1]
            . ', "\\@{}") '
            . ' : ref('
            . $_[1]
            . q{) eq 'ARRAY'};
    },
    parameterized_inline_generator => sub {
        my $self      = shift;
        my $parameter = shift;
        my $val       = shift;

        return
              '( ( Scalar::Util::blessed('
            . $val . ') && '
            . 'overload::Overloaded('
            . $val
            . ') && defined overload::Method('
            . $val
            . ', "\\@{}") ) || '
            . '( ref('
            . $val
            . ') eq "ARRAY" )'
            . '&& List::Util::all {'
            . $parameter->inline_check('$_') . ' } ' . '@{'
            . $val . '}' . ' )';
    },
);

declare(
    'HashRef',
    type_class => 'Specio::Constraint::Parameterizable',
    parent     => t('Ref'),
    inline     => sub {
        'Scalar::Util::blessed('
            . $_[1] . ') ? '
            . 'overload::Overloaded('
            . $_[1]
            . ') && defined overload::Method('
            . $_[1]
            . ', "%{}") '
            . ' : ref('
            . $_[1]
            . q{) eq 'HASH'};
    },
    parameterized_inline_generator => sub {
        my $self      = shift;
        my $parameter = shift;
        my $val       = shift;

        return
              '( ( Scalar::Util::blessed('
            . $val . ') && '
            . 'overload::Overloaded('
            . $val
            . ') && defined overload::Method('
            . $val
            . ', "%{}") ) || '
            . '( ref('
            . $val
            . ') eq "HASH" )'
            . '&& List::Util::all {'
            . $parameter->inline_check('$_') . ' } '
            . 'values %{'
            . $val . '}' . ' )';
    },
);

declare(
    'Maybe',
    type_class                     => 'Specio::Constraint::Parameterizable',
    parent                         => t('Item'),
    inline                         => sub {'1'},
    parameterized_inline_generator => sub {
        my $self      = shift;
        my $parameter = shift;
        my $val       = shift;

        return
              '!defined('
            . $val . ') ' . '|| ('
            . $parameter->inline_check($val) . ')';
    },
);

1;

# ABSTRACT: Implements type constraint objects for Perl's built-in types

__END__

=head1 DESCRIPTION

See the documentation in L<Specio> for a list of types that this library
implements.

This library uses L<Specio::Exporter> to export its types.

