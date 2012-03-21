package Type::Library::Builtins;

use strict;
use warnings;

use parent 'Type::Exporter';

use Class::Load qw( is_class_loaded );
use List::MoreUtils ();
use Scalar::Util qw( blessed openhandle );
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
        '('
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
        $_[0]->parent()->_inline_check( $_[1] ) . ' && !ref(' . $_[1] . ')';
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
        $_[0]->parent()->_inline_check( $_[1] ) . ' && (' 
            . 'ref(\\'
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
        $value_type->_inline_check( $_[1] )
            . ' && ( my $val = '
            . $_[1]
            . ' ) =~ /\\A-?[0-9]+(?:\\.[0-9]+)?\\z/';
    }
);

declare(
    'Int',
    parent => t('Num'),
    inline => sub {
        $value_type->_inline_check( $_[1] )
            . ' && ( my $val = '
            . $_[1]
            . ' ) =~ /\A-?[0-9]+\z/';
    }
);

declare(
    'CodeRef',
    parent => t('Ref'),
    inline => sub { 'ref(' . $_[1] . ') eq "CODE"' },
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
            . $parameter->_inline_check('$_') . ' } '
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
            . $parameter->_inline_check('$_') . ' } '
            . 'values %{$value}' . '}';
    },
);

1;
