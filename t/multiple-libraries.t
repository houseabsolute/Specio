use strict;
use warnings;
use encoding 'utf8';

use Test::Fatal;
use Test::More 0.88;

use Devel::PartialDump;
use Type::Library::Builtins;

use lib 't/lib';
use Type::Library::XY;

{
    for my $type (qw( X Y Str Undef )) {
        is(
            exception { ok( t($type), "type named $type is available" ) },
            undef,
            "no exception retrieving $type type"
        );
    }
}

done_testing();
