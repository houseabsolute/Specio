package Specio::Constraint::Intersection;

use strict;
use warnings;

our $VERSION = '0.52';

use List::Util 1.33 qw( all );
use Role::Tiny::With;
use Specio qw( _clone );
use Specio::OO;

use Specio::Constraint::Role::Interface;
with 'Specio::Constraint::Role::Interface';

{
    ## no critic (Subroutines::ProtectPrivateSubs)
    my $attrs = _clone( Specio::Constraint::Role::Interface::_attrs() );
    ## use critic

    for my $name (qw( _constraint _inline_generator )) {
        delete $attrs->{$name}{predicate};
        $attrs->{$name}{init_arg} = undef;
        $attrs->{$name}{lazy}     = 1;
        $attrs->{$name}{builder}
            = $name =~ /^_/ ? '_build' . $name : '_build_' . $name;
    }

    delete $attrs->{parent};

    delete $attrs->{name}{predicate};
    $attrs->{name}{lazy}    = 1;
    $attrs->{name}{builder} = '_build_name';

    $attrs->{of} = {
        isa      => 'ArrayRef',
        required => 1,
    };

    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    sub _attrs {
        return $attrs;
    }
}

sub parent {undef}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _has_parent {0}

sub _has_name {
    my $self = shift;
    return defined $self->name;
}

sub _build_name {
    my $self = shift;

    return unless all { $_->_has_name } @{ $self->of };
    return join q{ & }, map { $_->name } @{ $self->of };
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _has_constraint {
    my $self = shift;

    return !$self->_has_inline_generator;
}
## use critic

sub _build_constraint {
    return $_[0]->_optimized_constraint;
}

sub _build_optimized_constraint {
    my $self = shift;

    ## no critic (Subroutines::ProtectPrivateSubs)
    my @c = map { $_->_optimized_constraint } @{ $self->of };
    return sub {
        return all { $_->( $_[0] ) } @c;
    };
}

sub _has_inline_generator {
    my $self = shift;

    ## no critic (Subroutines::ProtectPrivateSubs)
    return all { $_->_has_inline_generator } @{ $self->of };
}

sub _build_inline_generator {
    my $self = shift;

    return sub {
        return '(' . (
            join q{ && },
            map { sprintf( '( %s )', $_->_inline_generator->( $_, $_[1] ) ) }
                @{ $self->of }
        ) . ')';
    }
}

sub _build_inline_environment {
    my $self = shift;

    my %env;
    for my $type ( @{ $self->of } ) {
        %env = (
            %env,
            %{ $type->inline_environment },
        );
    }

    return \%env;
}

__PACKAGE__->_ooify;

1;

# ABSTRACT: A class for intersection constraints

__END__

=for Pod::Coverage parent

=head1 SYNOPSIS

    my $type = Specio::Constraint::Untion->new(...);

=head1 DESCRIPTION

This is a specialized type constraint class for intersections, which will allow
a value which matches each one of several distinct types.

=head1 API

This class provides all of the same methods as L<Specio::Constraint::Simple>,
with a few differences:

=head2 Specio::Constraint::Intersection->new( ... )

The C<parent> parameter is ignored if it passed, as it is always C<undef>

The C<inline_generator> and C<constraint> parameters are also ignored. This
class provides its own default inline generator subroutine reference.

Finally, this class requires an additional parameter, C<of>. This must be an
arrayref of type objects.

=head2 $union->of

Returns an array reference of the individual types which makes up this
intersection.

=head1 ROLES

This class does the L<Specio::Constraint::Role::Interface> and
L<Specio::Role::Inlinable> roles.

