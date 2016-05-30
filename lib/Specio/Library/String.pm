package Specio::Library::String;

use strict;
use warnings;

our $VERSION = '0.15';

use parent 'Specio::Exporter';

use Specio::Library::Builtins;

use Specio::Declare;

declare(
    'NonEmptySimpleStr',
    parent => t('Str'),
    inline => sub {
        return
            sprintf(
            <<'EOF', $_[0]->parent->inline_check( $_[1] ), ( $_[1] ) x 3 );
(
    %s
    &&
    length %s > 0
    &&
    length %s <= 255
    &&
    %s !~ /[\n\r\x{2028}\x{2029}]/
)
EOF
    },
);

declare(
    'NonEmptyStr',
    parent => t('Str'),
    inline => sub {
        return
            sprintf( <<'EOF', $_[0]->parent->inline_check( $_[1] ), $_[1] );
(
    %s
    &&
    length %s
)
EOF
    },
);

declare(
    'SimpleStr',
    parent => t('Str'),
    inline => sub {
        return
            sprintf(
            <<'EOF', $_[0]->parent->inline_check( $_[1] ), ( $_[1] ) x 2 );
(
    %s
    &&
    length %s <= 255
    &&
    %s !~ /[\n\r\x{2028}\x{2029}]/
)
EOF
    },
);

1;
