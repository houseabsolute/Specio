use strict;
use warnings;

use Test::More 0.88;

use Type::Declare;
use Type::Library::Builtins;

my $anon = anon(
    parent => t('Str'),
    where  => sub { length $_[0] }
);

isa_ok( $anon, 'Type::Constraint::Simple', 'return value from anon()' );

ok( $anon->value_is_valid('x'),  q{anon type allows "x"} );
ok( !$anon->value_is_valid(q{}), 'anon type reject empty string' );

done_testing();
