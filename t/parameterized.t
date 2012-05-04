use strict;
use warnings;

use Test::More 0.88;

use Type::Declare;
use Type::Library::Builtins;

{
    my $arrayref = t('ArrayRef');

    ok(
        $arrayref->value_is_valid( [ {}, 42, 'foo' ] ),
        'ArrayRef does not care about member types'
    );

    my $from_method = t1($arrayref);

    is_deeply(
        $from_method->declared_at(),
        {
            filename => __FILE__,
            line     => 42,
            package  => 'main',
            sub      => 'main::t1',
        },
        'got the right declaration spot for type made from ->parameterize'
    );

    my $from_t = t2();

    is_deeply(
        $from_t->declared_at(),
        {
            filename => __FILE__,
            line     => 84,
            package  => 'main',
            sub      => 'main::t2',
        },
        'got the right declaration spot for type made from ->parameterize'
    );

    declare(
        'ArrayRefOfInt',
        parent => t( 'ArrayRef', of => t('Int') ),
    );

    ok(
        t('ArrayRefOfInt'),
        'there is an ArrayRefOfInt type declared'
    );

    my $anon = anon(
        parent => t( 'ArrayRef', of => t('Int') ),
    );

    for my $pair (
        [ $from_method,       '->parameterize()' ],
        [ $from_t,            't(...)' ],
        [ t('ArrayRefOfInt'), 'named type' ],
        [ $anon,              'anon type' ],
        ) {

        my ( $arrayref_of_int, $desc ) = @{$pair};

        ok(
            !$arrayref_of_int->value_is_valid( [ {}, 42, 'foo' ] ),
            "ArrayRef of Int [$desc] does care about member types"
        );

        ok(
            $arrayref_of_int->value_is_valid( [ -1, 42, 1_000_000 ] ),
            "ArrayRef of Int [$desc] accepts array ref of all integers"
        );

        ok(
            !$arrayref_of_int->value_is_valid( 42 ),
            "ArrayRef of Int [$desc] rejects integer"
        );

        ok(
            !$arrayref_of_int->value_is_valid( {} ),
            "ArrayRef of Int [$desc] rejects hashref"
        );
    }
}

done_testing();

sub t1 {
    my $arrayref = shift;
# line 42
    return $arrayref->parameterize( of => t('Int') );
}

sub t2 {
# line 84
    return t( 'ArrayRef', of => t('Int') ),;
}
