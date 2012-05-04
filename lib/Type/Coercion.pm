package Type::Coercion;

use strict;
use warnings;

use Moose;
use MooseX::Aliases;
with 'MooseX::Clone';

has from => (
    is       => 'ro',
    does     => 'Type::Constraint::Interface',
    required => 1,
);

has to => (
    is       => 'ro',
    does     => 'Type::Constraint::Interface',
    required => 1,
    weak_ref => 1,
);

has coercion => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => '_has_coercion',
    alias     => 'using',
);

has inline_generator => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => '_has_inline_generator',
    alias     => 'inline',
);

has inline_environment => (
    is      => 'ro',
    isa     => 'HashRef[Any]',
    lazy    => 1,
    default => sub { {} },
);

has _inlined_coercion => (
    is       => 'ro',
    isa      => 'CodeRef',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_inlined_coercion',
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

sub _inline_coercion {
    my $self = shift;
    return $self->inline_generator()->( $self, @_ );
}

sub _build_optimized_coercion {
    my $self = shift;

    if ( $self->can_be_inlined() ) {
        return $self->_inlined_coercion();
    }
    else {
        return $self->coercion();
    }
}

sub _build_inlined_constraint {
    my $self = shift;

    my $source = 'sub { ' . $self->_inline_coercion('$_[0]') . '}';

    return eval_closure(
        source      => $source,
        environment => $self->inline_environment(),
        description => 'inlined coercion from '
            . $self->from()->_description() . ' to '
            . $self->to()->_description(),
    );
}

__PACKAGE__->meta()->make_immutable();

1;
