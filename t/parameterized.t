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

    my @types = (
        $arrayref->parameterize( of => t('Int') ),
        t( 'ArrayRef', of => t('Int') ),
    );

    for my $arrayref_of_int (@types) {

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
