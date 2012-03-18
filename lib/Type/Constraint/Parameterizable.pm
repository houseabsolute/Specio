package Type::Constraint::Parameterizable;

use strict;
use warnings;
use namespace::autoclean;

use Moose;

with 'Type::Constraint::Interface';

has parameterized_constraint_generator => (
    is  => 'ro',
    isa => 'CodeRef',
);

has parameterized_inline_generator => (
    is  => 'ro',
    isa => 'CodeRef',
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $p     = $class->$orig(@_);

    if ( exists $p->{constraint} ) {
        die
            'A parameterizable constraint with a constraint parameter must also have a parameterized_constraint_generator'
            unless exists $p->{parameterized_constraint_generator};
    }

    if ( exists $p->{inline_generator} ) {
        die
            'A parameterizable constraint with an inline_generator parameter must also have a parameterized_inline_generator'
            unless exists $p->{parameterized_inline_generator};
    }

    return $p;
};

sub parameterize {
    my $self = shift;
    
}

__PACKAGE__->meta()->make_immutable();

1;
