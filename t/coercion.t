use strict;
use warnings;
use encoding 'utf8';

use Test::Fatal;
use Test::More 0.88;

use Type::Declare;
use Type::Library::Builtins;

{
    my $arrayref = t('ArrayRef');

    ok(
        !$arrayref->has_coercions(),
        'ArrayRef type object does not have coercions'
    );

    ok(
        !Type::Library::Builtins::t('ArrayRef')->has_coercions(),
        'ArrayRef type in Type::Library::Builtins package does not have coercions'
    );

    coerce(
        $arrayref,
        from  => t('Int'),
        using => sub { [ $_[0] ] },
    );

    ok( $arrayref->has_coercions(), 'ArrayRef type object has coercions' );

    ok(
        !Type::Library::Builtins::t('ArrayRef')->has_coercions(),
        'ArrayRef type in Type::Library::Builtins package does not have coercions (coercions only apply to local copy of type)'
    );

    ok(
        $arrayref->has_coercion_from_type( t('Int') ),
        'has a coercion for the Int type'
    );

    ok(
        !$arrayref->has_coercion_from_type( t('Str') ),
        'does not have a coercion for the Str type'
    );

    is_deeply(
        $arrayref->coerce_value(42),
        [42],
        'coerced int to arrayref',
    );

    like(
        exception { $arrayref->coerce_value(42.1) },
        qr/\QCould not find a coercion for 42.1/,
        'cannot coerced num to arrayref',
    );

    ok(
        !$arrayref->can_inline_coercion_and_check(),
        'cannot inline coercion and check for arrayref'
    );
}

{
    my $hashref = t('HashRef');

    coerce(
        $hashref,
        from             => t('ArrayRef'),
        inline_generator => sub {
            return '{ @{ ' . $_[1] . '} }';
        },
    );

    ok(
        $hashref->can_inline_coercion_and_check(),
        'can inline coercion and check for hashref'
    );

    coerce(
        $hashref,
        from             => t('Int'),
        inline_generator => sub {
            return '{ ' . $_[1] . ' => 1 }';
        },
    );

    ok(
        $hashref->can_inline_coercion_and_check(),
        'can inline coercion and check for hashref with two coercions'
    );
}

done_testing();
