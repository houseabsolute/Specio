package Type::Constraint::Interface;

use strict;
use warnings;
use namespace::autoclean;

use Devel::PartialDump;
use Eval::Closure qw( eval_closure );
use List::AllUtils qw( all );
use Sub::Name qw( subname );
use Try::Tiny;
use Type::Exception;

use Moose::Role;
use MooseX::Aliases;
with 'MooseX::Clone';

has name => (
    is        => 'ro',
    isa       => 'Str',
    predicate => '_has_name',
);

has parent => (
    is        => 'ro',
    does      => 'Type::Constraint::Interface',
    predicate => '_has_parent',
);

has declared_at => (
    is  => 'ro',
    isa => 'HashRef[Maybe[Str]]',
);

has constraint => (
    is        => 'rw',
    writer    => '_set_constraint',
    isa       => 'CodeRef',
    predicate => '_has_constraint',
    alias     => 'where',
);

has _optimized_constraint => (
    is       => 'ro',
    isa      => 'CodeRef',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_optimized_constraint',
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

has _inlined_constraint => (
    is       => 'ro',
    isa      => 'CodeRef',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_inlined_constraint',
);

has _ancestors => (
    is       => 'ro',
    isa      => 'ArrayRef',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_ancestors',
);

my $_default_message_generator = sub {
    my $self = shift;
    my $thing = shift;
    my $value = shift;

    return
          q{Validation failed for } 
        . $thing
        . q{ with value }
        . Devel::PartialDump->new()->dump($value);
};

has message_generator => (
    is      => 'ro',
    isa     => 'CodeRef',
    default => sub { $_default_message_generator },
    alias   => 'message',
);

has _description => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_description',
);

my $null_constraint = sub { 1 };

sub BUILD { }

around BUILD => sub {
    my $orig = shift;
    my $self = shift;

    unless ( $self->_has_constraint() || $self->_has_inline_generator() ) {
        $self->_set_constraint($null_constraint);
    }

    die
        'A type constraint should have either a constraint or inline_generator parameter, not both'
        if $self->_has_constraint() && $self->_has_inline_generator();

    return;
};

sub validate_or_die {
    my $self  = shift;
    my $value = shift;

    return if $self->value_is_valid($value);

    Type::Exception->throw(
        message => $self->message_generator()
            ->( $self, $self->_description(), $value ),
        type  => $self,
        value => $value,
    );
}

sub value_is_valid {
    my $self = shift;
    my $value = shift;

    return $self->_optimized_constraint()->($value);
}

sub _ancestors_and_self {
    my $self = shift;

    return ( ( reverse @{ $self->_ancestors() } ), $self );
}

sub is_anon {
    my $self = shift;

    return ! $self->_has_name();
}

sub has_real_constraint {
    my $self = shift;

    return ! $self->constraint() ne $null_constraint;
}

sub _inline_check {
    my $self = shift;
    return $self->inline_generator()->( $self, @_ );
}

sub _build_optimized_constraint {
    my $self = shift;

    if ( $self->can_be_inlined() ) {
        return $self->_inlined_constraint();
    }
    else {
        return $self->_constraint_with_parents();
    }
}

sub _constraint_with_parents {
    my $self = shift;

    my @constraints;
    for my $type ( $self->_ancestors_and_self() ) {
        next unless $type->has_real_constraint();

        # If a type can be inlined, we can use that and discard all of the
        # ancestors we've seen so far, since we can assume that the inlined
        # constraint does all of the ancestor checks in addition to its own.
        if ( $type->can_be_inlined() ) {
            @constraints = $type->_inlined_constraint();
        }
        else {
            push @constraints, $type->constraint();
        }
    }

    return $null_constraint unless @constraints;

    return subname(
        'optimized constraint for ' . $self->_description() => sub {
            all { $_->( $_[0] ) } @constraints;
        }
    );
}

sub can_be_inlined {
    my $self = shift;

    return $self->_has_inline_generator();
}

sub _build_ancestors {
    my $self = shift;

    my @parents;

    my $type = $self;
    while ( $type = $type->parent() ) {
        push @parents, $type;
    }

    return \@parents;
}

sub _build_inlined_constraint {
    my $self = shift;

    my $source = 'sub { ' . $self->_inline_check('$_[0]') . '}';

    return eval_closure(
        source      => $source,
        environment => $self->inline_environment(),
        description => 'inlined constraint for ' . $self->_description(),
    );
}

sub _build_description {
    my $self = shift;

    my $desc = $self->is_anon() ? 'anonymous type' : 'type named ' . $self->name();

    my $decl = $self->declared_at();
    $desc .= " declared in package $decl->{package} ($decl->{filename}) at line $decl->{line}";
    $desc .= " in sub named $decl->{sub}" if defined $decl->{sub};

    return $desc;
}

1;
