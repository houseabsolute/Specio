package Type::Library::Builtins;

use strict;
use warnings;

use parent 'Type::Exporter';

use Type::Declare -declare => [
    qw(
        Any
        Item
        Undef
        Defined
        Bool
        Value
        Ref
        Str
        Num
        Int
        )
];

#<<<
declare t('Any'),
    where { 1 },
    inline_with { '1' };

declare t('Item'),
    where { 1 },
    inline_with { '1' };

declare t('Undef'),
    parent t('Item'),
    where { !defined( $_[0] ) },
    inline_with {
        '!defined(' . $_[1] . ')';
    };

declare t('Defined'),
    parent t('Item'),
    where { defined( $_[0] ) },
    inline_with {
        'defined(' . $_[1] . ')';
    };

declare t('Bool'),
    parent t('Item'),
    where {
        !defined( $_[0] ) || $_[0] eq "" || "$_[0]" eq '1' || "$_[0]" eq '0';
    },
    inline_with {
        '(' .
            '!defined(' . $_[1] . ') ' .
            '|| ' . $_[1] . ' eq "" ' .
            '|| (' . $_[1] . '."") eq "1" ' .
            '|| (' . $_[1] . '."") eq "0"' .
        ')';
    };

declare t('Value'),
    parent t('Defined'),
    where { !ref( $_[0] ) },
    inline_with {
        $_[0]->parent()->_inline_check( $_[1] ) . ' && !ref(' . $_[1] . ')';
    };

declare t('Ref'),
    parent t('Defined'),
    where { ref( $_[0] ) },
    # no need to call parent - ref also checks for definedness
    inline_with { 'ref(' . $_[1] . ')' };

declare t('Str'),
    parent t('Value'),
    where {
        ref( \$_[0] ) eq 'SCALAR' || ref( \( my $val = $_[0] ) ) eq 'SCALAR';
    },
    inline_with {
        $_[0]->parent()->_inline_check( $_[1] ) .
        ' && (' .
            'ref(\\' . $_[1] . ') eq "SCALAR"' .
                ' || ref(\\(my $val = ' . $_[1] . ')) eq "SCALAR"' .
            ')'
        };

my $value_type = t('Value');
declare t('Num'),
    parent t('Str'),
    where {
        Scalar::Util::looks_like_number( $_[0] )
            # looks_like_number allows surrounding space and things like NaN, Inf, etc.
            && $_[0] =~ /^\A-?[0-9]/i;
    },
    inline_with {
        $value_type->_inline_check( $_[1] ) .
        ' && Scalar::Util::looks_like_number( ' . $_[1] . ' )' .
        ' && ( my $val = ' . $_[1] . ' ) =~ /^\\A-?[0-9]/i';
    };

declare t('Int'),
    parent t('Num'),
    where { ( my $val = $_[0] ) =~ /\A-?[0-9]+\z/ },
    inline_with {
        $value_type->_inline_check( $_[1] ) .
        ' && ( my $val = ' . $_[1] . ' ) =~ /\A-?[0-9]+\z/'
    };
#>>>

1;
