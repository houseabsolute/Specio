package Type::Constraint::Interface;

use strict;
use warnings;
use namespace::autoclean;

use Devel::PartialDump;
use List::AllUtils qw( all );
use Try::Tiny;

use Moose::Role;

has name => (
    is        => 'ro',
    isa       => 'Str',
    predicate => '_has_name',
);

has declared_at => (
    is  => 'ro',
    isa => 'HashRef[Str]',
);

my $null_constraint = sub { 1 };
has constraint => (
    is      => 'ro',
    isa     => 'CodeRef',
    default => sub { $null_constraint },
);

has inline_generator => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => '_has_inline_generator',
);

has inline_environment => (
    is        => 'ro',
    isa       => 'HashRef[Str]',
    predicate => '_has_inline_environment',
);

has _ancestors => (
    is       => 'ro',
    isa      => 'ArrayRef',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_ancestors',
);

my $_default_message_generator = sub {
    my $thing = shift;
    my $value = shift;

    return
          q{Validation failed for '} 
        . $thing
        . q{' with value }
        . Devel::PartialDump->new()->dump($value);
};

has message_generator => (
    is      => 'ro',
    isa     => 'CodeRef',
    default => sub { $_default_message_generator },
);

sub value_is_valid {
    my $self = shift;

    return all { $_->constraint()->(@_) } $self->_ancestors_and_self();
}

sub _ancestors_and_self {
    my $self = shift;

    return ( ( reverse @{ $self->_ancestors() } ), $self );
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

sub is_anon {
    my $self = shift;

    return ! $self->_has_name();
}

1;
