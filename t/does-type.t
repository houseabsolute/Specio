use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;

use Class::Load qw( try_load_class );
use Type::Declare;

{
    package Class::DoesNoRoles;

    sub new {
        return bless {}, shift;
    }
}

{
    package Role::MooseStyle;

    use Moose::Role;
}

{
    package Class::MooseStyle;

    use Moose;

    with 'Role::MooseStyle';
}

{
    my $any_does_moose = any_does_type(
        'AnyDoesMoose',
        role => 'Role::MooseStyle',
    );

    _test_any_type(
        $any_does_moose,
        'Class::MooseStyle'
    );

    my $object_does_moose = object_does_type(
        'ObjectDoesMoose',
        role => 'Role::MooseStyle',
    );

    _test_object_type(
        $object_does_moose,
        'Class::MooseStyle'
    );
}

SKIP:
{
    skip 'These tests require Mouse', 8
        unless try_load_class('Mouse');

    eval <<'EOF';
{
    package Role::MouseStyle;

    use Mouse::Role;
}

{
    package Class::MouseStyle;

    use Mouse;

    with 'Role::MouseStyle';
}
EOF

    my $any_does_moose = any_does_type(
        'AnyDoesMouse',
        role => 'Role::MouseStyle',
    );

    _test_any_type(
        $any_does_moose,
        'Class::MouseStyle'
    );

    my $object_does_moose = object_does_type(
        'ObjectDoesMouse',
        role => 'Role::MouseStyle',
    );

    _test_object_type(
        $object_does_moose,
        'Class::MouseStyle'
    );
}

SKIP:
{
    skip 'These tests require Moo', 8
        unless try_load_class('Moo');

    eval <<'EOF';
{
    package Role::MooStyle;

    use Moo::Role;
}

{
    package Class::MooStyle;

    use Moo;

    with 'Role::MooStyle';
}
EOF

    my $any_does_moose = any_does_type(
        'AnyDoesMoo',
        role => 'Role::MooStyle',
    );

    _test_any_type(
        $any_does_moose,
        'Class::MooStyle'
    );

    my $object_does_moose = object_does_type(
        'ObjectDoesMoo',
        role => 'Role::MooStyle',
    );

    _test_object_type(
        $object_does_moose,
        'Class::MooStyle'
    );
}

done_testing();

sub _test_any_type {
    my $type       = shift;
    my $class_name = shift;

    my $type_name = $type->name();

    ok(
        $type->value_is_valid($class_name),
        "$class_name class name is valid for $type_name"
    );

    ok(
        $type->value_is_valid( $class_name->new() ),
        "$class_name object is valid for $type_name"
    );

    ok(
        !$type->value_is_valid('Class::DoesNoRoles'),
        "Class::DoesNoRoles class name is not valid for $type_name"
    );

    ok(
        !$type->value_is_valid( Class::DoesNoRoles->new() ),
        "Class::DoesNoRoles object is not valid for $type_name"
    );
}

sub _test_object_type {
    my $type       = shift;
    my $class_name = shift;

    my $type_name = $type->name();

    ok(
        !$type->value_is_valid($class_name),
        "$class_name class name is not valid for $type_name"
    );

    ok(
        $type->value_is_valid( $class_name->new() ),
        "$class_name object is valid for $type_name"
    );

    ok(
        !$type->value_is_valid('Class::DoesNoRoles'),
        "Class::DoesNoRoles class name is not valid for $type_name"
    );

    ok(
        !$type->value_is_valid( Class::DoesNoRoles->new() ),
        "Class::DoesNoRoles object is not valid for $type_name"
    );
}
