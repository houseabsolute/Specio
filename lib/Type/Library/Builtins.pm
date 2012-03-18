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
    where  => sub { 1 },
    inline => sub { '1' }
);

declare(
    'Item',
    where  => sub { 1 },
    inline => sub { '1' }
);

declare(
    'Undef',
    parent => t('Item'),
    where  => sub { !defined( $_[0] ) },
    inline => sub {
        '!defined(' . $_[1] . ')';
    }
);

declare(
    'Defined',
    parent => t('Item'),
    where  => sub { defined( $_[0] ) },
    inline => sub {
        'defined(' . $_[1] . ')';
    }
);

declare(
    'Bool',
    parent => t('Item'),
    where  => sub {
        !defined( $_[0] ) || $_[0] eq "" || "$_[0]" eq '1' || "$_[0]" eq '0';
    },
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
    where  => sub { !ref( $_[0] ) },
    inline => sub {
        $_[0]->parent()->_inline_check( $_[1] ) . ' && !ref(' . $_[1] . ')';
    }
);

declare(
    'Ref',
    parent => t('Defined'),
    where  => sub { ref( $_[0] ) },

    # no need to call parent - ref also checks for definedness
    inline => sub { 'ref(' . $_[1] . ')' }
);

declare(
    'Str',
    parent => t('Value'),
    where  => sub {
        ref( \$_[0] ) eq 'SCALAR' || ref( \( my $val = $_[0] ) ) eq 'SCALAR';
    },
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
    where  => sub {
        # Scalar::Util::looks_like_number allows surrounding space and things
        # like NaN, Inf, etc.
        $_[0] =~ /\A-?[0-9]+(?:\.[0-9]+)?\z/;
    },
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
    where  => sub { ( my $val = $_[0] ) =~ /\A-?[0-9]+\z/ },
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
    where  => sub { ref( $_[0] ) eq 'CODE' },
    inline => sub { 'ref(' . $_[1] . ') eq "CODE"' },
);

declare(
    'RegexpRef',
    parent => t('Ref'),
    where  => \&_RegexpRef,
    inline => sub { 'Type::Library::Builtins::_RegexpRef(' . $_[1] . ')' },
);

declare(
    'GlobRef',
    parent => t('Ref'),
    where  => sub { ref( $_[0] ) eq 'GLOB' },
    inline => sub { 'ref(' . $_[1] . ') eq "GLOB"' },
);

# NOTE: scalar filehandles are GLOB refs, but a GLOB ref is not always a
# filehandle
declare(
    'FileHandle',
    parent => t('Ref'),
    where  => sub {
        ( ref( $_[0] ) eq "GLOB" && openhandle( $_[0] ) )
            || ( blessed( $_[0] ) && $_->isa("IO::Handle") );
    },
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
    where  => sub { blessed( $_[0] ) },
    inline => sub { 'Scalar::Util::blessed(' . $_[1] . ')' },
);

declare(
    'ClassName',
    parent => t('Str'),
    where  => sub { is_class_loaded( $_[0] ) },
    inline => sub { 'Class::Load::is_class_loaded(' . $_[1] . ')' },
);

declare(
    'ArrayRef',
    type_class => 'Type::Constraint::Parameterizable',
    parent     => t('Ref'),
    where      => sub { ref( $_[0] ) eq 'ARRAY' },
    inline => sub { 'ref(' . $_[1] . q{) eq 'ARRAY'} },
    parameterized_constraint_generator => sub {
        my $parameter  = shift;
        my $constraint = $parameter->_optimized_constraint();
        return sub {
            local $_;
            List::MoreUtils::all { $constraint->($_) } @{ $_[0] };
        };
    },
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

1;
