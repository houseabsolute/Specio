use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;

use B ();
use IO::File;
use Scalar::Util qw( blessed looks_like_number openhandle );
use Specio::DeclaredAt;
use Specio::Library::Builtins;

my $ZERO    = 0;
my $ONE     = 1;
my $INT     = 100;
my $NEG_INT = -100;
my $NUM     = 42.42;
my $NEG_NUM = -42.42;

my $EMPTY_STRING  = q{};
my $STRING        = 'foo';
my $NUM_IN_STRING = 'has 42 in it';
my $INT_WITH_NL1  = "1\n";
my $INT_WITH_NL2  = "\n1";

my $SCALAR_REF     = \( my $var );
my $SCALAR_REF_REF = \$SCALAR_REF;
my $ARRAY_REF      = [];
my $HASH_REF       = {};
my $CODE_REF       = sub { };

my $GLOB = do { no warnings 'once'; *GLOB_REF };
my $GLOB_REF = \$GLOB;

open my $FH, '<', $0 or die "Could not open $0 for the test";

my $FH_OBJECT = IO::File->new( $0, 'r' )
    or die "Could not open $0 for the test";

my $REGEX      = qr/../;
my $REGEX_OBJ  = bless qr/../, 'BlessedQR';
my $FAKE_REGEX = bless {}, 'Regexp';

my $OBJECT = bless {}, 'Foo';

my $UNDEF = undef;

{
    package Thing;

    sub foo { }
}

my $CLASS_NAME = 'Thing';

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

my $BOOL_OVERLOAD_TRUE  = BoolOverload->new(1);
my $BOOL_OVERLOAD_FALSE = BoolOverload->new(0);

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

my $STR_OVERLOAD_EMPTY      = StrOverload->new(q{});
my $STR_OVERLOAD_FULL       = StrOverload->new('full');
my $STR_OVERLOAD_CLASS_NAME = StrOverload->new('StrOverload');

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

my $NUM_OVERLOAD_ZERO        = NumOverload->new(0);
my $NUM_OVERLOAD_ONE         = NumOverload->new(1);
my $NUM_OVERLOAD_NEG         = NumOverload->new(-42);
my $NUM_OVERLOAD_DECIMAL     = NumOverload->new(42.42);
my $NUM_OVERLOAD_NEG_DECIMAL = NumOverload->new(42.42);

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

my $CODE_OVERLOAD = CodeOverload->new( sub { } );

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

my $REGEX_OVERLOAD = RegexOverload->new(qr/foo/);

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

local *FOO;
my $GLOB_OVERLOAD = GlobOverload->new( \*FOO );

local *BAR;
open BAR, '<', $0 or die "Could not open $0 for the test";
my $GLOB_OVERLOAD_FH = GlobOverload->new( \*BAR );

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

my $SCALAR_OVERLOAD = ScalarOverload->new('x');

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

my $ARRAY_OVERLOAD = ArrayOverload->new( [ 1, 2, 3 ] );

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

my $HASH_OVERLOAD = HashOverload->new( { x => 42, y => 84 } );

my %tests = (
    Any => {
        accept => [
            $ZERO,
            $ONE,
            $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $NUM_OVERLOAD_ZERO,
            $NUM_OVERLOAD_ONE,
            $NUM_OVERLOAD_NEG,
            $NUM_OVERLOAD_NEG_DECIMAL,
            $NUM_OVERLOAD_DECIMAL,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $STR_OVERLOAD_EMPTY,
            $STR_OVERLOAD_FULL,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $SCALAR_OVERLOAD,
            $ARRAY_REF,
            $ARRAY_OVERLOAD,
            $HASH_REF,
            $HASH_OVERLOAD,
            $CODE_REF,
            $CODE_OVERLOAD,
            $GLOB,
            $GLOB_REF,
            $GLOB_OVERLOAD,
            $GLOB_OVERLOAD_FH,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $REGEX_OVERLOAD,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    Item => {
        accept => [
            $ZERO,
            $ONE,
            $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $NUM_OVERLOAD_ZERO,
            $NUM_OVERLOAD_ONE,
            $NUM_OVERLOAD_NEG,
            $NUM_OVERLOAD_NEG_DECIMAL,
            $NUM_OVERLOAD_DECIMAL,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $STR_OVERLOAD_EMPTY,
            $STR_OVERLOAD_FULL,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $SCALAR_OVERLOAD,
            $ARRAY_REF,
            $ARRAY_OVERLOAD,
            $HASH_REF,
            $HASH_OVERLOAD,
            $CODE_REF,
            $CODE_OVERLOAD,
            $GLOB,
            $GLOB_REF,
            $GLOB_OVERLOAD,
            $GLOB_OVERLOAD_FH,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $REGEX_OVERLOAD,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    Defined => {
        accept => [
            $ZERO,
            $ONE,
            $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $NUM_OVERLOAD_ZERO,
            $NUM_OVERLOAD_ONE,
            $NUM_OVERLOAD_NEG,
            $NUM_OVERLOAD_NEG_DECIMAL,
            $NUM_OVERLOAD_DECIMAL,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $STR_OVERLOAD_EMPTY,
            $STR_OVERLOAD_FULL,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $SCALAR_OVERLOAD,
            $ARRAY_REF,
            $ARRAY_OVERLOAD,
            $HASH_REF,
            $HASH_OVERLOAD,
            $CODE_REF,
            $CODE_OVERLOAD,
            $GLOB,
            $GLOB_REF,
            $GLOB_OVERLOAD,
            $GLOB_OVERLOAD_FH,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $REGEX_OVERLOAD,
            $FAKE_REGEX,
            $OBJECT,
        ],
        reject => [
            $UNDEF,
        ],
    },
    Undef => {
        accept => [
            $UNDEF,
        ],
        reject => [
            $ZERO,
            $ONE,
            $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $NUM_OVERLOAD_ZERO,
            $NUM_OVERLOAD_ONE,
            $NUM_OVERLOAD_NEG,
            $NUM_OVERLOAD_NEG_DECIMAL,
            $NUM_OVERLOAD_DECIMAL,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $STR_OVERLOAD_EMPTY,
            $STR_OVERLOAD_FULL,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $SCALAR_OVERLOAD,
            $ARRAY_REF,
            $ARRAY_OVERLOAD,
            $HASH_REF,
            $HASH_OVERLOAD,
            $CODE_REF,
            $CODE_OVERLOAD,
            $GLOB,
            $GLOB_REF,
            $GLOB_OVERLOAD,
            $GLOB_OVERLOAD_FH,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $REGEX_OVERLOAD,
            $FAKE_REGEX,
            $OBJECT,
        ],
    },
    Bool => {
        accept => [
            $ZERO,
            $ONE,
            $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $EMPTY_STRING,
            $UNDEF,
        ],
        reject => [
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $NUM_OVERLOAD_ZERO,
            $NUM_OVERLOAD_ONE,
            $NUM_OVERLOAD_NEG,
            $NUM_OVERLOAD_NEG_DECIMAL,
            $NUM_OVERLOAD_DECIMAL,
            $STRING,
            $NUM_IN_STRING,
            $STR_OVERLOAD_EMPTY,
            $STR_OVERLOAD_FULL,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $SCALAR_OVERLOAD,
            $ARRAY_REF,
            $ARRAY_OVERLOAD,
            $HASH_REF,
            $HASH_OVERLOAD,
            $CODE_REF,
            $CODE_OVERLOAD,
            $GLOB,
            $GLOB_REF,
            $GLOB_OVERLOAD,
            $GLOB_OVERLOAD_FH,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $REGEX_OVERLOAD,
            $FAKE_REGEX,
            $OBJECT,
        ],
    },
    Maybe => {
        accept => [
            $ZERO,
            $ONE,
            $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $NUM_OVERLOAD_ZERO,
            $NUM_OVERLOAD_ONE,
            $NUM_OVERLOAD_NEG,
            $NUM_OVERLOAD_NEG_DECIMAL,
            $NUM_OVERLOAD_DECIMAL,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $STR_OVERLOAD_EMPTY,
            $STR_OVERLOAD_FULL,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $SCALAR_OVERLOAD,
            $ARRAY_REF,
            $ARRAY_OVERLOAD,
            $HASH_REF,
            $HASH_OVERLOAD,
            $CODE_REF,
            $CODE_OVERLOAD,
            $GLOB,
            $GLOB_REF,
            $GLOB_OVERLOAD,
            $GLOB_OVERLOAD_FH,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $REGEX_OVERLOAD,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    Value => {
        accept => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $GLOB,
        ],
        reject => [
            $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $STR_OVERLOAD_EMPTY,
            $STR_OVERLOAD_FULL,
            $NUM_OVERLOAD_ZERO,
            $NUM_OVERLOAD_ONE,
            $NUM_OVERLOAD_NEG,
            $NUM_OVERLOAD_NEG_DECIMAL,
            $NUM_OVERLOAD_DECIMAL,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $SCALAR_OVERLOAD,
            $ARRAY_REF,
            $ARRAY_OVERLOAD,
            $HASH_REF,
            $HASH_OVERLOAD,
            $CODE_REF,
            $CODE_OVERLOAD,
            $GLOB_REF,
            $GLOB_OVERLOAD,
            $GLOB_OVERLOAD_FH,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $REGEX_OVERLOAD,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    Ref => {
        accept => [
            $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $STR_OVERLOAD_EMPTY,
            $STR_OVERLOAD_FULL,
            $NUM_OVERLOAD_ZERO,
            $NUM_OVERLOAD_ONE,
            $NUM_OVERLOAD_NEG,
            $NUM_OVERLOAD_NEG_DECIMAL,
            $NUM_OVERLOAD_DECIMAL,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $SCALAR_OVERLOAD,
            $ARRAY_REF,
            $ARRAY_OVERLOAD,
            $HASH_REF,
            $HASH_OVERLOAD,
            $CODE_REF,
            $CODE_OVERLOAD,
            $GLOB_REF,
            $GLOB_OVERLOAD,
            $GLOB_OVERLOAD_FH,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $REGEX_OVERLOAD,
            $FAKE_REGEX,
            $OBJECT,
        ],
        reject => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $GLOB,
            $UNDEF,
        ],
    },
    Num => {
        accept => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $NUM_OVERLOAD_ZERO,
            $NUM_OVERLOAD_ONE,
            $NUM_OVERLOAD_NEG,
            $NUM_OVERLOAD_NEG_DECIMAL,
            $NUM_OVERLOAD_DECIMAL,
        ],
        reject => [
            $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $STR_OVERLOAD_EMPTY,
            $STR_OVERLOAD_FULL,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $SCALAR_OVERLOAD,
            $ARRAY_REF,
            $ARRAY_OVERLOAD,
            $HASH_REF,
            $HASH_OVERLOAD,
            $CODE_REF,
            $CODE_OVERLOAD,
            $GLOB,
            $GLOB_REF,
            $GLOB_OVERLOAD,
            $GLOB_OVERLOAD_FH,
            $FH,
            $FH_OBJECT,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $REGEX,
            $REGEX_OBJ,
            $REGEX_OVERLOAD,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    Int => {
        accept => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM_OVERLOAD_ZERO,
            $NUM_OVERLOAD_ONE,
            $NUM_OVERLOAD_NEG,
        ],
        reject => [
            $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $NUM,
            $NEG_NUM,
            $NUM_OVERLOAD_NEG_DECIMAL,
            $NUM_OVERLOAD_DECIMAL,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $STR_OVERLOAD_EMPTY,
            $STR_OVERLOAD_FULL,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $SCALAR_OVERLOAD,
            $ARRAY_REF,
            $ARRAY_OVERLOAD,
            $HASH_REF,
            $HASH_OVERLOAD,
            $CODE_REF,
            $CODE_OVERLOAD,
            $GLOB,
            $GLOB_REF,
            $GLOB_OVERLOAD,
            $GLOB_OVERLOAD_FH,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $REGEX_OVERLOAD,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    Str => {
        accept => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $STR_OVERLOAD_EMPTY,
            $STR_OVERLOAD_FULL,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
        ],
        reject => [
            $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $NUM_OVERLOAD_ZERO,
            $NUM_OVERLOAD_ONE,
            $NUM_OVERLOAD_NEG,
            $NUM_OVERLOAD_NEG_DECIMAL,
            $NUM_OVERLOAD_DECIMAL,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $SCALAR_OVERLOAD,
            $ARRAY_REF,
            $ARRAY_OVERLOAD,
            $HASH_REF,
            $HASH_OVERLOAD,
            $CODE_REF,
            $CODE_OVERLOAD,
            $GLOB,
            $GLOB_REF,
            $GLOB_OVERLOAD,
            $GLOB_OVERLOAD_FH,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $REGEX_OVERLOAD,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    ScalarRef => {
        accept => [
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $SCALAR_OVERLOAD,
        ],
        reject => [
            $ZERO,
            $ONE,
            $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $NUM_OVERLOAD_ZERO,
            $NUM_OVERLOAD_ONE,
            $NUM_OVERLOAD_NEG,
            $NUM_OVERLOAD_NEG_DECIMAL,
            $NUM_OVERLOAD_DECIMAL,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $STR_OVERLOAD_EMPTY,
            $STR_OVERLOAD_FULL,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $ARRAY_REF,
            $ARRAY_OVERLOAD,
            $HASH_REF,
            $HASH_OVERLOAD,
            $CODE_REF,
            $CODE_OVERLOAD,
            $GLOB,
            $GLOB_REF,
            $GLOB_OVERLOAD,
            $GLOB_OVERLOAD_FH,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $REGEX_OVERLOAD,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    ArrayRef => {
        accept => [
            $ARRAY_REF,
            $ARRAY_OVERLOAD,
        ],
        reject => [
            $ZERO,
            $ONE,
            $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $NUM_OVERLOAD_ZERO,
            $NUM_OVERLOAD_ONE,
            $NUM_OVERLOAD_NEG,
            $NUM_OVERLOAD_NEG_DECIMAL,
            $NUM_OVERLOAD_DECIMAL,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $STR_OVERLOAD_EMPTY,
            $STR_OVERLOAD_FULL,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $SCALAR_OVERLOAD,
            $HASH_REF,
            $HASH_OVERLOAD,
            $CODE_REF,
            $CODE_OVERLOAD,
            $GLOB,
            $GLOB_REF,
            $GLOB_OVERLOAD,
            $GLOB_OVERLOAD_FH,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $REGEX_OVERLOAD,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    HashRef => {
        accept => [
            $HASH_REF,
            $HASH_OVERLOAD,
        ],
        reject => [
            $ZERO,
            $ONE,
            $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $NUM_OVERLOAD_ZERO,
            $NUM_OVERLOAD_ONE,
            $NUM_OVERLOAD_NEG,
            $NUM_OVERLOAD_NEG_DECIMAL,
            $NUM_OVERLOAD_DECIMAL,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $STR_OVERLOAD_EMPTY,
            $STR_OVERLOAD_FULL,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $SCALAR_OVERLOAD,
            $ARRAY_REF,
            $ARRAY_OVERLOAD,
            $CODE_REF,
            $CODE_OVERLOAD,
            $GLOB,
            $GLOB_REF,
            $GLOB_OVERLOAD,
            $GLOB_OVERLOAD_FH,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $REGEX_OVERLOAD,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    CodeRef => {
        accept => [
            $CODE_REF,
            $CODE_OVERLOAD,
        ],
        reject => [
            $ZERO,
            $ONE,
            $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $NUM_OVERLOAD_ZERO,
            $NUM_OVERLOAD_ONE,
            $NUM_OVERLOAD_NEG,
            $NUM_OVERLOAD_NEG_DECIMAL,
            $NUM_OVERLOAD_DECIMAL,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $STR_OVERLOAD_EMPTY,
            $STR_OVERLOAD_FULL,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $SCALAR_OVERLOAD,
            $ARRAY_REF,
            $ARRAY_OVERLOAD,
            $HASH_REF,
            $HASH_OVERLOAD,
            $GLOB,
            $GLOB_REF,
            $GLOB_OVERLOAD,
            $GLOB_OVERLOAD_FH,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $REGEX_OVERLOAD,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    RegexpRef => {
        accept => [
            $REGEX,
            $REGEX_OBJ,
            $REGEX_OVERLOAD,
        ],
        reject => [
            $ZERO,
            $ONE,
            $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $NUM_OVERLOAD_ZERO,
            $NUM_OVERLOAD_ONE,
            $NUM_OVERLOAD_NEG,
            $NUM_OVERLOAD_NEG_DECIMAL,
            $NUM_OVERLOAD_DECIMAL,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $STR_OVERLOAD_EMPTY,
            $STR_OVERLOAD_FULL,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $SCALAR_OVERLOAD,
            $ARRAY_REF,
            $ARRAY_OVERLOAD,
            $HASH_REF,
            $HASH_OVERLOAD,
            $CODE_REF,
            $CODE_OVERLOAD,
            $GLOB,
            $GLOB_REF,
            $GLOB_OVERLOAD,
            $GLOB_OVERLOAD_FH,
            $FH,
            $FH_OBJECT,
            $OBJECT,
            $UNDEF,
            $FAKE_REGEX,
        ],
    },
    GlobRef => {
        accept => [
            $GLOB_REF,
            $GLOB_OVERLOAD,
            $GLOB_OVERLOAD_FH,
            $FH,
        ],
        reject => [
            $ZERO,
            $ONE,
            $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $NUM_OVERLOAD_ZERO,
            $NUM_OVERLOAD_ONE,
            $NUM_OVERLOAD_NEG,
            $NUM_OVERLOAD_NEG_DECIMAL,
            $NUM_OVERLOAD_DECIMAL,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $STR_OVERLOAD_EMPTY,
            $STR_OVERLOAD_FULL,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $SCALAR_OVERLOAD,
            $ARRAY_REF,
            $ARRAY_OVERLOAD,
            $HASH_REF,
            $HASH_OVERLOAD,
            $CODE_REF,
            $CODE_OVERLOAD,
            $GLOB,
            $FH_OBJECT,
            $OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $REGEX_OVERLOAD,
            $FAKE_REGEX,
            $UNDEF,
        ],
    },
    FileHandle => {
        accept => [
            $FH,
            $FH_OBJECT,
            $GLOB_OVERLOAD_FH,
        ],
        reject => [
            $ZERO,
            $ONE,
            $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $NUM_OVERLOAD_ZERO,
            $NUM_OVERLOAD_ONE,
            $NUM_OVERLOAD_NEG,
            $NUM_OVERLOAD_NEG_DECIMAL,
            $NUM_OVERLOAD_DECIMAL,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $STR_OVERLOAD_EMPTY,
            $STR_OVERLOAD_FULL,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $SCALAR_OVERLOAD,
            $ARRAY_REF,
            $ARRAY_OVERLOAD,
            $HASH_REF,
            $HASH_OVERLOAD,
            $CODE_REF,
            $CODE_OVERLOAD,
            $GLOB,
            $GLOB_REF,
            $GLOB_OVERLOAD,
            $OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $REGEX_OVERLOAD,
            $FAKE_REGEX,
            $UNDEF,
        ],
    },
    Object => {
        accept => [
            $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $STR_OVERLOAD_EMPTY,
            $STR_OVERLOAD_FULL,
            $NUM_OVERLOAD_ZERO,
            $NUM_OVERLOAD_ONE,
            $NUM_OVERLOAD_NEG,
            $NUM_OVERLOAD_NEG_DECIMAL,
            $NUM_OVERLOAD_DECIMAL,
            $CODE_OVERLOAD,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $REGEX_OVERLOAD,
            $FAKE_REGEX,
            $GLOB_OVERLOAD,
            $GLOB_OVERLOAD_FH,
            $SCALAR_OVERLOAD,
            $ARRAY_OVERLOAD,
            $HASH_OVERLOAD,
            $OBJECT,
        ],
        reject => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $UNDEF,
        ],
    },
    ClassName => {
        accept => [
            $CLASS_NAME,
            $STR_OVERLOAD_CLASS_NAME,
        ],
        reject => [
            $ZERO,
            $ONE,
            $BOOL_OVERLOAD_TRUE,
            $BOOL_OVERLOAD_FALSE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $NUM_OVERLOAD_ZERO,
            $NUM_OVERLOAD_ONE,
            $NUM_OVERLOAD_NEG,
            $NUM_OVERLOAD_NEG_DECIMAL,
            $NUM_OVERLOAD_DECIMAL,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $STR_OVERLOAD_EMPTY,
            $STR_OVERLOAD_FULL,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $SCALAR_OVERLOAD,
            $ARRAY_REF,
            $ARRAY_OVERLOAD,
            $HASH_REF,
            $HASH_OVERLOAD,
            $CODE_REF,
            $CODE_OVERLOAD,
            $GLOB,
            $GLOB_REF,
            $GLOB_OVERLOAD,
            $GLOB_OVERLOAD_FH,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $REGEX_OVERLOAD,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
);

for my $name ( sort keys %tests ) {
    test_constraint( $name, $tests{$name} );
}

my %substr_test_str = (
    ClassName => 'x' . $CLASS_NAME,
);

# We need to test that the Str constraint (and types that derive from it)
# accept the return val of substr() - which means passing that return val
# directly to the checking code
foreach my $type_name (qw( Str Num Int ClassName )) {
    my $str = $substr_test_str{$type_name} || '123456789';

    my $type = t($type_name);

    my $name = $type->name();

    my $not_inlined = $type->_constraint_with_parents();

    my $inlined;
    if ( $type->can_be_inlined() ) {
        $inlined = $type->_generated_inline_sub();
    }

    ok(
        $type->value_is_valid( substr( $str, 1, 5 ) ),
        $type_name . ' accepts return val from substr using ->value_is_valid'
    );
    ok(
        $not_inlined->( substr( $str, 1, 5 ) ),
        $type_name
            . ' accepts return val from substr using unoptimized constraint'
    );
    ok(
        $inlined->( substr( $str, 1, 5 ) ),
        $type_name
            . ' accepts return val from substr using inlined constraint'
    );

    # only Str accepts empty strings.
    next unless $type_name eq 'Str';

    ok(
        $type->value_is_valid( substr( $str, 0, 0 ) ),
        $type_name
            . ' accepts empty return val from substr using ->value_is_valid'
    );
    ok(
        $not_inlined->( substr( $str, 0, 0 ) ),
        $type_name
            . ' accepts empty return val from substr using unoptimized constraint'
    );
    ok(
        $inlined->( substr( $str, 0, 0 ) ),
        $type_name
            . ' accepts empty return val from substr using inlined constraint'
    );
}

close $FH
    or warn "Could not close the filehandle $0 for test";
$FH_OBJECT->close
    or warn "Could not close the filehandle $0 for test";

done_testing();

sub test_constraint {
    my $type  = shift;
    my $tests = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $type = t($type) unless blessed $type;

    my $name = $type->name();

    my $not_inlined = $type->_constraint_with_parents();

    my $inlined;
    if ( $type->can_be_inlined() ) {
        $inlined = $type->_generated_inline_sub();
    }

    for my $accept ( @{ $tests->{accept} || [] } ) {
        my $described = describe($accept);
        ok(
            $type->value_is_valid($accept),
            "$name accepts $described using ->value_is_valid"
        );
        ok(
            $not_inlined->($accept),
            "$name accepts $described using non-inlined constraint"
        );
        if ($inlined) {
            ok(
                $inlined->($accept),
                "$name accepts $described using inlined constraint"
            );
        }
    }

    for my $reject ( @{ $tests->{reject} || [] } ) {
        my $described = describe($reject);
        ok(
            !$type->value_is_valid($reject),
            "$name rejects $described using ->value_is_valid"
        );
        if ($inlined) {
            ok(
                !$inlined->($reject),
                "$name rejects $described using inlined constraint"
            );
        }
    }

    if ( $type->isa('Specio::Constraint::Parameterizable') ) {
        my $parameterized = Specio::Constraint::Simple->new(
            name        => $type->name() . 'OfItem',
            parent      => $type->parameterize( of => t('Item') ),
            declared_at => Specio::DeclaredAt->new_from_caller(0),
        );
        test_constraint( $parameterized, $tests );
    }
}

sub describe {
    my $val = shift;

    return 'undef' unless defined $val;

    if ( !ref $val ) {
        return q{''} if $val eq q{};

        $val =~ s/\n/\\n/g;

        return looks_like_number($val) ? $val : B::perlstring($val);
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
