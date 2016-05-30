use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;

use Try::Tiny;
use Specio::Library::Builtins;

{
    my $str = t('Str');

    my $e = exception {
        $str->validate_or_die(undef);
    };

    ok( $e, 'validate_or_die throws something when given a bad value' );
    isa_ok( $e, 'Specio::Exception' );

    like(
        $e->message(),
        qr/Validation failed for type named Str .+ with value undef/,
        'exception contains expected error'
    );

    try {
        $str->validate_or_die( [] );
    }
    catch {
        $e = $_;
    };

    like(
        $e->message(),
        qr/Validation failed for type named Str .+ with value \[\s*\]/,
        'exception contains expected error'
    );
}

done_testing();
