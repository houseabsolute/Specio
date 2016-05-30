package Specio::Library::Perl;

use strict;
use warnings;

our $VERSION = '0.15';

use parent 'Specio::Exporter';

use Specio::Library::String;

use Specio::Declare;

my $package_inline = sub {
    return sprintf( <<'EOF', $_[0]->parent->inline_check( $_[1] ), $_[1] );
(
    %s
    &&
    %s =~ /\A[^\W\d]\w*(?:::\w+)*\z/
)
EOF
};

declare(
    'PackageName',
    parent => t('NonEmptyStr'),
    inline => $package_inline,
);

declare(
    'ModuleName',
    parent => t('NonEmptyStr'),
    inline => $package_inline,
);

1;
