package Type::Constraint::Simple;

use strict;
use warnings;
use namespace::autoclean;

use Moose;

with 'Type::Constraint::Interface';

has parent => (
    is        => 'ro',
    does      => 'Type::Constraint::Interface',
    predicate => '_has_parent',
);

__PACKAGE__->meta()->make_immutable();

1;
