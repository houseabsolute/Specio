use strict;
use warnings;
use encoding 'utf8';

use Test::More 0.88;

use Devel::PartialDump;
use Type::Library::Builtins;

my $dpd = Devel::PartialDump->new();

{
    my $str = t('Str');
    isa_ok( $str, 'Type::Constraint::Simple' );

    for my $value ( q{}, 'foo', 'bar::baz', "\x{3456}", 0, 42 ) {
        ok(
            $str->value_is_valid($value),
            $dpd->dump($value) . ' is a valid Str value'
        );
    }

    no warnings 'once';
    my $foo = 'foo';
    for my $value ( undef, \42, \$foo, [], {}, sub { }, *glob, \*globref ) {
        ok(
            !$str->value_is_valid($value),
            $dpd->dump($value) . ' is not a valid Str value'
        );
    }
}

done_testing();
