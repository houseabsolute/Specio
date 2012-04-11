use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;

use Type::Declare;

{

    package Foo;

    sub new {
        return bless {}, shift;
    }

    sub foo { 42 }
}

{

    package Bar;

    our @ISA = 'Foo';

    sub bar { 84 }
}

{
    package Quux;

    sub whatever { }
}

{
    my $tc = object_can_type(
        'Need2',
        methods => [qw( foo bar )],
    );

    is( $tc->name(), 'Need2', 'constraint has the expected name' );
    ok(
        $tc->value_is_valid( Bar->new() ),
        'Bar object is valid for named ObjectCan type'
    );

    eval { $tc->validate_or_die( Foo->new() ) };
    my $e = $@;
    like(
        $e->message(),
        qr/\QFoo is missing the 'bar' method/,
        'got expected error message for failure with ObjectCan type'
    );
}

{
    my $tc = object_can_type(
        'Need3',
        methods => [qw( foo bar baz )],
    );

    ok(
        !$tc->value_is_valid( Bar->new() ),
        'Bar object is not valid for named ObjectCan type'
    );
}

{
    my $tc = object_can_type(
        methods => [qw( foo bar )],
    );

    ok(
        $tc->value_is_valid( Bar->new() ),
        'Bar object is valid for anon ObjectCan type'
    );
}

{
    my $tc = object_can_type(
        methods => [qw( foo bar baz )],
    );

    ok(
        !$tc->value_is_valid( Bar->new() ),
        'Bar object is not valid for anon ObjectCan type'
    );
}

{
    my $tc = object_isa_type('Foo');

    is( $tc->name(), 'Foo', 'name defaults to class name' );

    ok(
        $tc->value_is_valid( Foo->new() ),
        'Foo object is valid for isa type (requires Foo)'
    );

    ok(
        $tc->value_is_valid( Bar->new() ),
        'Bar object is valid for isa type (requires Foo)'
    );
}

{
    my $tc = object_isa_type('Quux');

    ok(
        !$tc->value_is_valid( Foo->new() ),
        'Foo object is not valid for isa type (requires NonExistent)'
    );

    eval { $tc->validate_or_die( Foo->new() ) };
    my $e = $@;
    like(
        $e->message(),
        qr/\Q/,
        'got expected error message for failure with ObjectCan type'
    );
}

done_testing();
