package Test::Types;

use strict;
use warnings;

use B ();
use IO::File;
use Scalar::Util qw( blessed looks_like_number openhandle );
use Specio::Library::Builtins;
use Specio::Library::Numeric;
use Specio::Library::Perl;
use Specio::Library::String;
use Test::Fatal;
use Test::More 0.96;

use Exporter qw( import );

our $ZERO    = 0;
our $ONE     = 1;
our $INT     = 100;
our $NEG_INT = -100;
our $NUM     = 42.42;
our $NEG_NUM = -42.42;

our $EMPTY_STRING  = q{};
our $STRING        = 'foo';
our $NUM_IN_STRING = 'has 42 in it';
our $INT_WITH_NL1  = "1\n";
our $INT_WITH_NL2  = "\n1";

our $SCALAR_REF = do {
    ## no critic (Variables::ProhibitUnusedVariables)
    \( my $var );
};
our $SCALAR_REF_REF = \$SCALAR_REF;
our $ARRAY_REF      = [];
our $HASH_REF       = {};
our $CODE_REF       = sub { };

our $GLOB_REF = \*GLOB;

our $FH;
## no critic (InputOutput::RequireBriefOpen)
open $FH, '<', $0 or die "Could not open $0 for the test";

our $FH_OBJECT = IO::File->new( $0, 'r' )
    or die "Could not open $0 for the test";

our $REGEX      = qr/../;
our $REGEX_OBJ  = bless qr/../, 'BlessedQR';
our $FAKE_REGEX = bless {}, 'Regexp';

our $OBJECT = bless {}, 'Foo';

our $UNDEF = undef;

## no critic (Modules::ProhibitMultiplePackages)
{
    package Thing;

    sub foo { }
}

our $CLASS_NAME = 'Thing';

{
    package BoolOverload;

    use overload
        'bool' => sub { ${ $_[0] } },
        fallback => 0;

    sub new {
        my $bool = $_[1];
        bless \$bool, __PACKAGE__;
    }
}

our $BOOL_OVERLOAD_TRUE  = BoolOverload->new(1);
our $BOOL_OVERLOAD_FALSE = BoolOverload->new(0);

{
    package StrOverload;

    use overload
        q{""} => sub { ${ $_[0] } },
        fallback => 0;

    sub new {
        my $str = $_[1];
        bless \$str, __PACKAGE__;
    }
}

our $STR_OVERLOAD_EMPTY      = StrOverload->new(q{});
our $STR_OVERLOAD_FULL       = StrOverload->new('full');
our $STR_OVERLOAD_CLASS_NAME = StrOverload->new('StrOverload');

{
    package NumOverload;

    use overload
        q{0+} => sub { ${ $_[0] } },
        '+'   => sub { ${ $_[0] } + $_[1] },
        fallback => 0;

    sub new {
        my $num = $_[1];
        bless \$num, __PACKAGE__;
    }
}

our $NUM_OVERLOAD_ZERO        = NumOverload->new(0);
our $NUM_OVERLOAD_ONE         = NumOverload->new(1);
our $NUM_OVERLOAD_NEG         = NumOverload->new(-42);
our $NUM_OVERLOAD_DECIMAL     = NumOverload->new(42.42);
our $NUM_OVERLOAD_NEG_DECIMAL = NumOverload->new(42.42);

{
    package CodeOverload;

    use overload
        q{&{}} => sub { ${ $_[0] } },
        fallback => 0;

    sub new {
        my $code = $_[1];
        bless \$code, __PACKAGE__;
    }
}

our $CODE_OVERLOAD = CodeOverload->new( sub { } );

{
    package RegexOverload;

    use overload
        q{qr} => sub { ${ $_[0] } },
        fallback => 0;

    sub new {
        my $regex = $_[1];
        bless \$regex, __PACKAGE__;
    }
}

our $REGEX_OVERLOAD = RegexOverload->new(qr/foo/);

{
    package GlobOverload;

    use overload
        q[*{}] => sub { ${ $_[0] } },
        fallback => 0;

    sub new {
        my $glob = $_[1];
        bless \$glob, __PACKAGE__;
    }
}

{
    package ScalarOverload;

    use overload
        q[${}] => sub { ${ $_[0] } },
        fallback => 0;

    sub new {
        my $scalar = $_[1];
        bless \$scalar, __PACKAGE__;
    }
}

our $SCALAR_OVERLOAD = ScalarOverload->new('x');

{
    package ArrayOverload;

    use overload
        q[@{}] => sub { $_[0] },
        fallback => 0;

    sub new {
        my $array = $_[1];
        bless $array, __PACKAGE__;
    }
}

our $ARRAY_OVERLOAD = ArrayOverload->new( [ 1, 2, 3 ] );

{
    package HashOverload;

    use overload
        q[%{}] => sub { $_[0] },
        fallback => 0;

    sub new {
        my $hash = $_[1];
        bless $hash, __PACKAGE__;
    }
}

our $HASH_OVERLOAD = HashOverload->new( { x => 42, y => 84 } );

my @vals;

BEGIN {
    open my $fh, '<', $INC{'Test/Types.pm'} or die $!;
    while (<$fh>) {
        push @vals, $1 if /^our (\$[A-Z0-9_]+)(?: +=|;)/;
    }
}

## no critic (Modules::ProhibitAutomaticExportation)
our @EXPORT = ( @vals, 'test_constraint', 'describe' );

sub test_constraint {
    my $type      = shift;
    my $tests     = shift;
    my $describer = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $type = t($type) unless blessed $type;

    subtest(
        ( $type->name || '<anon>' ),
        sub {
            my $not_inlined = $type->_constraint_with_parents();

            my $inlined;
            if ( $type->can_be_inlined() ) {
                $inlined = $type->_generated_inline_sub();
            }

            for my $accept ( @{ $tests->{accept} || [] } ) {
                my $described = $describer->($accept);

                ok(
                    $type->value_is_valid($accept),
                    "accepts $described using ->value_is_valid"
                );
                is(
                    exception { $type->($accept) },
                    undef,
                    "accepts $described using subref overloading"
                );
                ok(
                    $not_inlined->($accept),
                    "accepts $described using non-inlined constraint"
                );
                if ($inlined) {
                    ok(
                        $inlined->($accept),
                        "accepts $described using inlined constraint"
                    );
                }
            }

            for my $reject ( @{ $tests->{reject} || [] } ) {
                my $described = $describer->($reject);
                ok(
                    !$type->value_is_valid($reject),
                    "rejects $described using ->value_is_valid"
                );
                if ($inlined) {
                    ok(
                        !$inlined->($reject),
                        "rejects $described using inlined constraint"
                    );
                }
            }
        }
    );
}

sub describe {
    my $val = shift;

    return 'undef' unless defined $val;

    if ( !ref $val ) {
        return q{''} if $val eq q{};

        return looks_like_number($val)
            && $val !~ /\n/ ? $val : B::perlstring($val);
    }

    return 'open filehandle'
        if openhandle $val && !blessed $val;

    if ( blessed $val ) {
        my $desc = ( ref $val ) . ' object';
        if ( $val->isa('StrOverload') ) {
            $desc .= ' (' . describe("$val") . ')';
        }
        elsif ( $val->isa('BoolOverload') ) {
            $desc .= ' (' . ( $val ? 'true' : 'false' ) . ')';
        }
        elsif ( $val->isa('NumOverload') ) {
            $desc .= ' (' . describe( ${$val} ) . ')';
        }

        return $desc;
    }
    else {
        return ( ref $val ) . ' reference';
    }
}

1;
