use strict;
use warnings;

use Test::More 0.88;

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

    for my $arrayref_of_int ( $from_method, $from_t ) {
        ok(
            !$arrayref_of_int->value_is_valid( [ {}, 42, 'foo' ] ),
            'ArrayRef of Int does care about member types'
        );

        ok(
            $arrayref_of_int->value_is_valid( [ -1, 42, 1_000_000 ] ),
            'ArrayRef of Int accepts array ref of all integers'
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
