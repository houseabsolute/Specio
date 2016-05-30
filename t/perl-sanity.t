use strict;
use warnings;

use lib 't/lib';

use Test::More 0.96;
use Test::Types;

use B ();
use Specio::Library::String;

my %tests = (
    PackageName => {
        accept => [
            $CLASS_NAME,
            $STR_OVERLOAD_CLASS_NAME, qw(
                Specio
                Spec::Library::Builtins
                strict
                _Foo
                A123::456
                ),
            "Has::Chinese::\x{3403}::In::It"
        ],
        reject => [
            $EMPTY_STRING,
            $STR_OVERLOAD_EMPTY,
            qw(
                0Foo
                Foo:Bar
                Foo:::Bar
                Foo:
                Foo::
                Foo::Bar::
                ::Foo
                ),
            'Has::Spaces In It',
        ],
    },
);

$tests{ModuleName} = $tests{PackageName};

for my $name ( sort keys %tests ) {
    test_constraint( $name, $tests{$name}, \&describe );
}

done_testing();
