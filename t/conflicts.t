use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;

use lib 't/lib';
use Type::Library::XY;

require Type::Library::Conflict;

like(
    exception { Type::Library::Conflict->import() },
    qr/\QThe main package already has a type named X/,
    'Got an exception when a library import conflicts with already declared types'
);

done_testing();
