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

__PACKAGE__->meta()->make_immutable();

1;
