package Type::Coercion;

use strict;
use warnings;

use Moose;
use MooseX::Aliases;

with 'MooseX::Clone', 'Type::Role::Inlinable';

has from => (
    is       => 'ro',
    does     => 'Type::Constraint::Role::Interface',
    required => 1,
);

has to => (
    is       => 'ro',
    does     => 'Type::Constraint::Role::Interface',
    required => 1,
    weak_ref => 1,
);

has coercion => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => '_has_coercion',
    alias     => 'using',
);

has _optimized_coercion => (
    is       => 'ro',
    isa      => 'CodeRef',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_optimized_coercion',
);

sub BUILD {
    my $self = shift;

    die
        'A type coercion should have either a coercion or inline_generator parameter, not both'
        if $self->_has_coercion() && $self->_has_inline_generator();

    return;
}

sub coerce {
    my $self  = shift;
    my $value = shift;

    return $self->_optimized_coercion()->($value);
}

sub inline_coercion {
    my $self = shift;

    return $self->inline_generator()->( $self, @_ )
}

sub _build_optimized_coercion {
    my $self = shift;

    if ( $self->_has_inline_generator() ) {
        return $self->_inlined_coercion();
    }
    else {
        return $self->coercion();
    }
}

sub can_be_inlined {
    my $self = shift;

    return $self->_has_inline_generator() && $self->to()->can_be_inlined();
}

sub _build_description {
    my $self = shift;

    my $desc
        = 'coercion from '
        . ( $self->from()->name() // 'anon type' ) . ' to '
        . ( $self->to()->name()   // 'anon type' );

    $desc .= q{ } . $self->_declaration_description();

    return $desc;
}

__PACKAGE__->meta()->make_immutable();

1;
