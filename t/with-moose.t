use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;

{
    package Foo;

    use Type::Declare;
    use Type::Library::Builtins;

    use Moose;

    ::is(
        ::exception{ has size => (
                is  => 'ro',
                isa => t('Int'),
            );
        },
        undef,
        'no exception passing a Type object as the isa parameter for a Moose attr'
    );

    has numbers => (
        is  => 'ro',
        isa => t( 'ArrayRef', of => t('Int') ),
    );

    my $ucstr = declare(
        'UCStr',
        parent => t('Str'),
        where  => sub { $_[0] =~ /^[A-Z]+$/ },
    );

    coerce(
        $ucstr,
        from  => t('Str'),
        using => sub { return uc $_[0] },
    );

    has ucstr => (
        is     => 'ro',
        isa    => $ucstr,
        coerce => 1,
    );

    my $ucstr2 = declare(
        'Ucstr2',
        parent    => t('Str'),
        inline_as => sub {
            my $type      = shift;
            my $value_var = shift;

            return $value_var . ' =~ /^[A-Z]+$/';
        },
    );

    coerce(
        $ucstr2,
        from  => t('Str'),
        using => sub { return uc $_[0] },
    );

    has ucstr2 => (
        is     => 'ro',
        isa    => $ucstr2,
        coerce => 1,
    );

    my $ucstr3 = declare(
        'Ucstr3',
        parent => t('Str'),
        where  => sub { $_[0] =~ /^[A-Z]+$/ },
    );

    coerce(
        $ucstr3,
        from             => t('Str'),
        inline_generator => sub {
            my $coercion  = shift;
            my $value_var = shift;

            return 'uc ' . $value_var;
        },
    );

    has ucstr3 => (
        is     => 'ro',
        isa    => $ucstr3,
        coerce => 1,
    );

    my $ucstr4 = declare(
        'Ucstr4',
        parent    => t('Str'),
        inline_as => sub {
            my $type      = shift;
            my $value_var = shift;

            return $value_var . ' =~ /^[A-Z]+$/';
        },
    );

    coerce(
        $ucstr4,
        from             => t('Str'),
        inline_generator => sub {
            my $coercion  = shift;
            my $value_var = shift;

            return 'uc ' . $value_var;
        },
    );

    has ucstr4 => (
        is     => 'ro',
        isa    => $ucstr4,
        coerce => 1,
    );
}

is(
    exception { Foo->new( size => 42 ) },
    undef,
    'no exception with new( size => $int )'
);

like(
    exception { Foo->new( size => 'foo' ) },
    qr/\QAttribute (size) does not pass the type constraint/,
    'got exception with new( size => $str )'
);

is(
    exception { Foo->new( numbers => [ 1, 2, 3 ] ) },
    undef,
    'no exception with new( numbers => [$int, $int, $int] )'
);

is(
    exception { Foo->new( ucstr => 'ABC' ) },
    undef,
    'no exception with new( ucstr => $ucstr )'
);

{
    my $foo;
    is(
        exception { $foo = Foo->new( ucstr => 'abc' ) },
        undef,
        'no exception with new( ucstr => $lcstr )'
    );

    is(
        $foo->ucstr(),
        'ABC',
        'ucstr attribute was coerced to upper case'
    );
}

{
    my $foo;
    is(
        exception { $foo = Foo->new( ucstr2 => 'abc' ) },
        undef,
        'no exception with new( ucstr2 => $lcstr )'
    );

    is(
        $foo->ucstr2(),
        'ABC',
        'ucstr2 attribute was coerced to upper case'
    );
}

{
    my $foo;
    is(
        exception { $foo = Foo->new( ucstr3 => 'abc' ) },
        undef,
        'no exception with new( ucstr3 => $lcstr )'
    );

    is(
        $foo->ucstr3(),
        'ABC',
        'ucstr3 attribute was coerced to upper case'
    );
}

{
    my $foo;
    is(
        exception { $foo = Foo->new( ucstr4 => 'abc' ) },
        undef,
        'no exception with new( ucstr4 => $lcstr )'
    );

    is(
        $foo->ucstr4(),
        'ABC',
        'ucstr4 attribute was coerced to upper case'
    );
}

{
    package Bar;

    use Type::Library::Builtins;

    use Moose;

    ::is(
        ::exception{ has native => (
                traits => ['Array'],
                is     => 'ro',
                isa    => t( 'ArrayRef', of => t('Int') ),
            );
        },
        undef,
        'no exception creating native Array attr where isa => ArrayRef of Int'
    );

    ::like(
        ::exception{ has native2 => (
                traits => ['Array'],
                is     => 'ro',
                isa    => t('Str'),
            );
        },
        qr/\QThe type constraint for native2 must be a subtype of ArrayRef but it's a Str/,
        'got exception creating native Array attr where isa => Str'
    );

}

done_testing();
