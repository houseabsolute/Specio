use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;

use IO::File;
use Scalar::Util qw( blessed openhandle );
use Type::Library::Builtins;

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

my $GLOB     = do { no warnings 'once'; *GLOB_REF };
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

my %tests = (
    Any => {
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
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    Item => {
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
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    Defined => {
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
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
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
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
        ],
    },
    Bool => {
        accept => [
            $ZERO,
            $ONE,
            $EMPTY_STRING,
            $UNDEF,
        ],
        reject => [
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
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
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
        ],
    },
    Maybe => {
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
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
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
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    Ref => {
        accept => [
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
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
        ],
        reject => [
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $REGEX,
            $REGEX_OBJ,
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
        ],
        reject => [
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
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
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
            $INT_WITH_NL1,
            $INT_WITH_NL2,
        ],
        reject => [
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    ScalarRef => {
        accept => [
            $SCALAR_REF,
            $SCALAR_REF_REF,
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
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    ArrayRef => {
        accept => [
            $ARRAY_REF,
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
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    HashRef => {
        accept => [
            $HASH_REF,
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
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    CodeRef => {
        accept => [
            $CODE_REF,
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
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    RegexpRef => {
        accept => [
            $REGEX,
            $REGEX_OBJ,
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
            $FH_OBJECT,
            $OBJECT,
            $UNDEF,
            $FAKE_REGEX,
        ],
    },
    GlobRef => {
        accept => [
            $GLOB_REF,
            $FH,
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
            $FH_OBJECT,
            $OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $UNDEF,
        ],
    },
    FileHandle => {
        accept => [
            $FH,
            $FH_OBJECT,
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
            $OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $UNDEF,
        ],
    },
    Object => {
        accept => [
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
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
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
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
        $inlined = $type->_inlined_constraint();
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
        $type_name . ' accepts empty return val from substr using ->value_is_valid'
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

    unless ( blessed $type ) {
        $type = eval { t($type) }
            or return;#BAIL_OUT("No such type $type!");
    }

    my $name = $type->name();

    my $not_inlined = $type->_constraint_with_parents();

    my $inlined;
    if ( $type->can_be_inlined() ) {
        $inlined = $type->_inlined_constraint();
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
}

sub describe {
    my $val = shift;

    return 'undef' unless defined $val;

    if ( !ref $val ) {
        return q{''} if $val eq q{};

        $val =~ s/\n/\\n/g;

        return $val;
    }

    return 'open filehandle'
        if openhandle $val && !blessed $val;

    return blessed $val
        ? ( ref $val ) . ' object'
        : ( ref $val ) . ' reference';
}
