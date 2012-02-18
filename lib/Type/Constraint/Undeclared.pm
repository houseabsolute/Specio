package Type::Constraint::Undeclared;

use strict;
use warnings;
use namespace::autoclean;

use Moose;

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

__PACKAGE__->meta()->make_immutable();

1;
