package Type::Library::Builtins;

use strict;
use warnings;

use parent 'Type::Exporter';

use Class::Load qw( is_class_loaded );
use List::MoreUtils ();
use overload ();
use Scalar::Util ();
use Type::Constraint::Parameterizable;
use Type::Declare;

XSLoader::load(
    __PACKAGE__,
    exists $Type::Library::Builtins::{VERSION}
    ? ${ $Type::Library::Builtins::{VERSION} }
    : ()
);

declare(
    'Any',
    inline => sub { '1' }
);

declare(
    'Item',
    inline => sub { '1' }
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
        '( ( Scalar::Util::blessed('
            . $_[1] . ') && '
            . ' overload::Overloaded('
            . $_[1]
            . ') && defined overload::Method('
            . $_[1]
            . ', "0+") && '
            . '( my $val1 = '
            . $_[1]
            . ' + 0 ) =~ /\A-?[0-9]+\z/ ) )'
            . ' || ( ( '
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
        '( Scalar::Util::blessed('
            . $_[1] . ') && '
            . ' overload::Overloaded('
            . $_[1]
            . ') && defined overload::Method('
            . $_[1]
            . ', "&{}") ) '
            . ' || ( ref('
            . $_[1]
            . ') eq "CODE" )';
    },
);

declare(
    'RegexpRef',
    parent => t('Ref'),
    inline => sub { 'Type::Library::Builtins::_RegexpRef(' . $_[1] . ')' },
);

declare(
    'GlobRef',
    parent => t('Ref'),
    inline => sub { 'ref(' . $_[1] . ') eq "GLOB"' },
);

# NOTE: scalar filehandles are GLOB refs, but a GLOB ref is not always a
# filehandle
declare(
    'FileHandle',
    parent => t('Ref'),
    inline => sub {
        '(ref('
            . $_[1]
            . ') eq "GLOB" '
            . '&& Scalar::Util::openhandle('
            . $_[1] . ')) '
            . '|| (Scalar::Util::blessed('
            . $_[1] . ') ' . '&& '
            . $_[1]
            . '->isa("IO::Handle"))';
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
    inline => sub { 'Class::Load::is_class_loaded(' . $_[1] . ')' },
);

declare(
    'ScalarRef',
    type_class => 'Type::Constraint::Parameterizable',
    parent     => t('Ref'),
    inline     => sub {
        'ref( '
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
              '( ref( ' 
            . $val
            . q{ ) eq 'SCALAR' || ref( }
            . $val
            . q{ ) eq 'REF' ) } . ' && '
            . $parameter->inline_check( '${ ( ' . $val . ' ) }' );
    },
);

declare(
    'ArrayRef',
    type_class => 'Type::Constraint::Parameterizable',
    parent     => t('Ref'),
    inline     => sub { 'ref(' . $_[1] . q{) eq 'ARRAY'} },
    parameterized_inline_generator => sub {
        my $self      = shift;
        my $parameter = shift;
        my $val       = shift;

        return
              'do {'
            . 'my $value = '
            . $val . ';'
            . q{ref($value) eq 'ARRAY' }
            . '&& List::MoreUtils::all {'
            . $parameter->inline_check('$_') . ' } '
            . '@{$value}' . '}';
    },
);

declare(
    'HashRef',
    type_class => 'Type::Constraint::Parameterizable',
    parent     => t('Ref'),
    inline     => sub { 'ref(' . $_[1] . q{) eq 'HASH'} },
    parameterized_inline_generator => sub {
        my $self      = shift;
        my $parameter = shift;
        my $val       = shift;

        return
              'do {'
            . 'my $value = '
            . $val . ';'
            . q{ref($value) eq 'HASH' }
            . '&& List::MoreUtils::all {'
            . $parameter->inline_check('$_') . ' } '
            . 'values %{$value}' . '}';
    },
);

declare(
    'Maybe',
    type_class                     => 'Type::Constraint::Parameterizable',
    parent                         => t('Ref'),
    inline                         => sub { '1' },
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
