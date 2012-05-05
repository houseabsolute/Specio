package Type;

use strict;
use warnings;

1;

# ABSTRACT: Type constraints and coercions for Perl

__END__

=head1 SYNOPSIS

  package MyApp::Type::Library;

  use Type::Declare;
  use Type::Library::Builtins;

  declare(
      'PositiveInt',
      parent => t('Int'),
      inline => sub {
          $_[0]->parent()->inline_check( $_[1] ) . ' && ( ' . $_[1] . ' > 0';
      },
  );

  # or ...

  declare(
      'PositiveInt',
      parent => t('Int'),
      where  => sub { $_[0] > 0 },
  );

  declare(
      'ArrayRefOfPositiveInt',
      parent => t(
          'ArrayRef',
          of => t('PositiveInt'),
      ),
  );

  coerce(
      'ArrayRefOfPositiveInt',
      from  => t('PositiveInt'),
      using => sub { [ $_[0] ] },
  );

  any_can_type(
      'Duck',
      methods => [ 'duck_walk', 'quack' ],
  );

  object_isa_type('MyApp::Person');

=head1 DESCRIPTION

B<WARNING: This thing is very alpha.>

The C<Type> distribution provides classes for representing type constraints
and coercion, along with syntax sugar for declaring them.

Note that this is not a proper type system for Perl. Nothing in this
distribution will magically make the Perl interpreter start checking a value's
type on assignment to a variable. In fact, there's no built-in way to apply a
type to a variable at all.

Instead, you can explicitly check a value against a type, and optionally
coerce values to that type.

My long-term goal is to replace Moose's built-in types and L<MooseX::Types>
with this module.

=head1 WHAT IS A TYPE?

At it's core, a type is simply a constraint. A constraint is code that checks
a value and returns true or false. Most constraints are represented by
L<Type::Constraint::Simple> objects, though there are some other type
constraint classes for specialized constraint types.

Types can be named or anonymous, and they can have a parent type. 
