package Type::Library::Builtins;

use strict;
use warnings;

use parent 'Type::Exporter';

use Type::Declare;

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
        Scalar::Util::looks_like_number( $_[0] )

            # looks_like_number allows surrounding space and things like NaN, Inf, etc.
            && $_[0] =~ /^\A-?[0-9]/i;
    },
    inline => sub {
        $value_type->_inline_check( $_[1] )
            . ' && Scalar::Util::looks_like_number( '
            . $_[1] . ' )'
            . ' && ( my $val = '
            . $_[1]
            . ' ) =~ /^\\A-?[0-9]/i';
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

1;
