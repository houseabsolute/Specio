package Type::Exception;

use strict;
use warnings;
use namespace::autoclean;

use Moose;

extends 'Throwable::Error';

has type => (
    is       => 'ro',
    does     => 'Type::Constraint::Role::Interface',
    required => 1,
);

has value => (
    is       => 'ro',
    required => 1,
);

# Throwable::Error does the StackTrace::Auto role, which has a modifier on
# new() for some reason.
__PACKAGE__->meta()->make_immutable( inline_constructor => 0 );

1;

# ABSTRACT: A Throwable::Error subclass for type constraint failures

=head1 DESCRIPTION

  use Try::Tiny;

  try {
      $type->validate_or_die($value);
  }
  catch {
      if ( $_->isa('Type::Exception') ) {
          print $_->message(), "\n";
          print $_->type()->name(), "\n";
          print $_->value(), "\n";
      }
  };

=head1 DESCRIPTION

This is a subclass of L<Throwable::Error> which adds a few additional
attributes specific to type constraint failures.

=head1 API

The two attributes it adds are C<type> and C<value>, both of which are
required. The C<type> must be a L<Type::Constraint::Role::Interface> object,
and the C<value> can be anything (including C<undef>).
