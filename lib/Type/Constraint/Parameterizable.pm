package Type::Constraint::Parameterizable;

use strict;
use warnings;
use namespace::autoclean;

use Moose;

with 'Type::Constraint::Interface';

has parameterized_constraint_generator => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

has parameterized_inline_generator => (
    is  => 'ro',
    isa => 'CodeRef',
);

sub parameterize {
    my $self = shift;
    
}

__PACKAGE__->meta()->make_immutable();

1;
