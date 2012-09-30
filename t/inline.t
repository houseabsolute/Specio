use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;

use Eval::Closure qw( eval_closure );
use Type::Library::Builtins;

{
    my $str = t('Str');
    my $int = t('Int');

    my ( $str_source, $str_env ) = $str->inline_coercion_and_check('$value1');
    my ( $int_source, $int_env ) = $int->inline_coercion_and_check('$value2');

    my $sub
        = 'sub { '
        . 'my $value1 = shift;'
        . 'my $value2 = shift;'
        . 'my $str_val = '
        . $str_source . ';'
        . 'my $int_val = '
        . $int_source . ';'
        . 'return ($str_val, $int_val)' . ' }';

    my $coerce_and_check;
    is(
        exception {
            $coerce_and_check = eval_closure(
                source      => $sub,
                environment => {
                    %{$str_env},
                    %{$int_env},
                },
                description => 'inlined coerce and check sub for str and int',
            );
        },
        undef,
        'no exception evaling a closure for str and int inlining in one sub',
    );

    is_deeply(
        [ $coerce_and_check->( 'string', 42 ) ],
        [ 'string', 42 ],
        'both types pass check and are returned'
    );

    like(
        exception { $coerce_and_check->( [], 42 ) },
        qr/Validation failed for type named Str/,
        'got exception passing arrayref for Str value'
    );

    like(
        exception { $coerce_and_check->( 'string', [] ) },
        qr/Validation failed for type named Int/,
        'got exception passing arrayref for Int value'
    );

}

done_testing();
