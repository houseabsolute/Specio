use strict;
use warnings;

use FindBin qw( $Bin );

my $lib_path;

BEGIN {
    for my $dir ( map {"$Bin/$_"} qw( lib ../../t/lib ) ) {
        if ( -f "$dir/Specio/Library/CannotSub.pm" ) {
            $lib_path = "$dir";
            last;
        }
    }
}

use lib "$lib_path";

use Test::Fatal;
use Test::More 0.96;

use Specio::Library::Builtins;
use Specio::Library::XY;

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
