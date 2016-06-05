package Specio::Library::Union;

use strict;
use warnings;

use parent 'Specio::Exporter';

use Specio::Declare;
use Specio::Library::Builtins;

my $locale_object = declare(
    'LocaleObject',
    parent => t('Object'),
    inline => sub {
        <<"EOF";
(
    $_[1]->isa('DateTime::Locale::FromData')
    || $_[1]->isa('DateTime::Locale::Base')
)
EOF
    },
);

union(
    'Union',
    of => [ t('Str'), $locale_object ],
);

1;
