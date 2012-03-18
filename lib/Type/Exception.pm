package Type::Exception;

use strict;
use warnings;
use namespace::autoclean;

use Moose;

extends 'Throwable::Error';

has type => (
    is       => 'ro',
    does     => 'Type::Constraint::Interface',
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
