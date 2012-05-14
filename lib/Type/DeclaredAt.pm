package Type::DeclaredAt;

use strict;
use warnings;

use Moose;

has package => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has filename => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has line => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has subroutine => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_subroutine',
);

sub new_from_caller {
    my $class = shift;
    my $depth = shift;

    my %p;
    @p{qw( package filename line )} = ( caller($depth) )[ 0, 1, 2 ];

    my $sub = ( caller( $depth + 1 ) )[3];
    $p{subroutine} = $sub if defined $sub;

    return $class->new(%p);
}

sub description {
    my $self = shift;

    my $package  = $self->package();
    my $filename = $self->filename();
    my $line     = $self->line();

    my $desc = "declared in package $package ($filename) at line $line";
    if ( $self->has_subroutine() ) {
        $desc .= ' in sub named ' . $self->subroutine();
    }

    return $desc;
}

__PACKAGE__->meta()->make_immutable();

1;

__END__
