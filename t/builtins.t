use strict;
use warnings;
use encoding 'utf8';

use Test::More 0.88;

use Devel::PartialDump;
use Specio::Declare;
use Specio::Library::Builtins;

my $dpd = Devel::PartialDump->new();

{
    my $str = t('Str');
    isa_ok( $str, 'Specio::Constraint::Simple' );
    like(
        $str->declared_at()->filename(),
        qr/Builtins\.pm/,
        'declared_at has the right filename'
    );

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

is(
    t('Str')->parent()->name(),
    'Value',
    'parent of Str is Value'
);

my $str_clone = t('Str')->clone();

for my $name (qw( Str Value Defined Item )) {
    ok(
        t('Str')->is_a_type_of( t($name) ),
        "Str is_a_type_of($name)"
    );

    next if $name eq 'Str';

    ok(
        $str_clone->is_a_type_of( t($name) ),
        "Str clone is_a_type_of($name)"
    );
}

for my $name (qw( Maybe ArrayRef Object )) {
    ok(
        !t('Str')->is_a_type_of( t($name) ),
        "Str ! is_a_type_of($name)"
    );

    ok(
        !$str_clone->is_a_type_of( t($name) ),
        "Str clone ! is_a_type_of($name)"
    );
}

for my $type ( t('Str'), $str_clone ) {
    ok(
        $type->is_same_type_as( t('Str') ),
        $type->name() . ' is_same_type_as Str'
    );
}

done_testing();
