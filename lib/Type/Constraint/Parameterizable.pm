package Type::Constraint::Parameterizable;

use strict;
use warnings;
use namespace::autoclean;

use MooseX::Params::Validate qw( validated_list );
use Type::Constraint::Parameterized;
use Type::DeclaredAt;

use Moose;

with 'Type::Constraint::Role::Interface';

has parameterized_constraint_generator => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => '_has_parameterized_constraint_generator',
);

has parameterized_inline_generator => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => '_has_parameterized_inline_generator',
);

sub BUILD {
    my $self = shift;

    if ( $self->_has_constraint() ) {
        die
            'A parameterizable constraint with a constraint parameter must also have a parameterized_constraint_generator'
            unless $self->_has_parameterized_constraint_generator();
    }

    if ( $self->_has_inline_generator() ) {
        die
            'A parameterizable constraint with an inline_generator parameter must also have a parameterized_inline_generator'
            unless $self->_has_parameterized_inline_generator();
    }

    return;
}

sub parameterize {
    my $self = shift;
    my ( $parameter, $declared_at ) = validated_list(
        \@_,
        of          => { does => 'Type::Constraint::Role::Interface' },
        declared_at => {
            isa      => 'Type::DeclaredAt',
            optional => 1,
        },
    );

    # This isn't a default so as to avoid generating it even when they
    # parameter is already set.
    $declared_at //= Type::DeclaredAt->new_from_caller(1),

    my %p = (
        parent      => $self,
        parameter   => $parameter,
        declared_at => $declared_at,
    );

    if ( $self->_has_parameterized_constraint_generator() ) {
        $p{constraint}
            = $self->parameterized_constraint_generator()->($parameter);
    }
    else {
        my $ig = $self->parameterized_inline_generator();
        $p{inline_generator} = sub { $ig->( shift, $parameter, @_ ) };
    }

    return Type::Constraint::Parameterized->new(%p);
}

__PACKAGE__->meta()->make_immutable();

1;
