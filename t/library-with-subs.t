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

use Specio::Library::WithSubs;

ok( t('Int'),                   'Int type is available' );
ok( t('PositiveInt'),           'PositiveInt type is available' );
ok( __PACKAGE__->can('is_Int'), 'is_Int() was exported from library' );
ok(
    __PACKAGE__->can('is_PositiveInt'),
    'is_PositiveInt() was exported from library'
);

done_testing();
