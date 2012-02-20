use strict;
use warnings;

use Test::More 0.88;

{
    package Foo;
    use namespace::autoclean;
    use Type::Library::Builtins;
}

ok( ! Foo->can('t'), 't sub is cleaned by namespace::autoclean' );

done_testing();
