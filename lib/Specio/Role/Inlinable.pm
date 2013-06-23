package Specio::Role::Inlinable;

use strict;
use warnings;
use namespace::autoclean;

use Sub::Quote qw( quoted_from_sub unquote_sub );

BEGIN {
    my $has_sub_name = eval { require Sub::Name; 1 };
    use constant HAS_SUB_NAME => $has_sub_name;
}

use Moose::Role;

requires '_build_description', '_inlinable_thing';

has _generated_inline_sub => (
    is       => 'ro',
    isa      => 'CodeRef',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_generated_inline_sub',
);

has _can_be_inlined => (
    is       => 'ro',
    isa      => 'Bool',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_can_be_inlined',
);

has declared_at => (
    is       => 'ro',
    isa      => 'Specio::DeclaredAt',
    required => 1,
);

has _description => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_description',
);

sub _build_can_be_inlined {
    my $self = shift;

    my $thing = $self->_inlinable_thing();

    return quoted_from_sub($thing) ? 1 : 0;
}

sub _build_generated_inline_sub {
    my $self = shift;

    my $sub = unquote_sub( $self->_inlinable_thing() );

    return $sub unless HAS_SUB_NAME;
    return Sub::Name::subname(
        'inlined sub for ' . $self->_description() => $sub );
}

sub _clean_eval { eval $_[0] }

# The $embedded parameter basically means "use the @_ from the existing scope
# because $_[0] contains the value we are validating."
sub _inline_thing {
    my $self     = shift;
    my $embedded = shift;

    my $quoted = quoted_from_sub( $self->_inlinable_thing() );

    my $code = Sub::Quote::inlinify(
        $quoted->[1],
        '@_',
        Sub::Quote::capture_unroll( '$_[1]', $quoted->[2], 4 ),
        ( $embedded ? () : 'local' )
    );

    return $code;
}

1;

# ABSTRACT: A role for things which can be inlined (type constraints and coercions)

__END__

=head1 DESCRIPTION

This role implements a common API for inlinable things, type constraints and
coercions. It is fully documented in the relevant classes.

