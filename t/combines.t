use strict;
use warnings;

use FindBin qw( $Bin );

my $lib_path;

# These tests get copied to the `xt` dir for the pure-Perl tests, so we need to find `t/lib` from
# multiple directories.
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

use Specio::Library::Combines;

{
    for my $type (qw( X Y Str Undef )) {
        is(
            exception { ok( t($type), "type named $type is available" ) },
            undef,
            "no exception retrieving $type type - exported by combining library"
        );
    }
}

done_testing();
