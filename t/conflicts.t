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

use Specio::Library::XY;

require Specio::Library::Conflict;

like(
    exception { Specio::Library::Conflict->import },
    qr/\QThe main package already has a type named X/,
    'Got an exception when a library import conflicts with already declared types'
);

done_testing();
