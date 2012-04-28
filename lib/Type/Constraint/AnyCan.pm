package Type::Constraint::AnyCan;

use strict;
use warnings;
use namespace::autoclean;

use B ();
use Scalar::Util;
use Type::Library::Builtins;

use Moose;

with 'Type::Constraint::Role::CanType';

my $Defined = t('Defined');
has '+parent' => (
    init_arg => undef,
    default  => sub { $Defined },
);

my $_inline_generator = sub {
    my $self = shift;
    my $val  = shift;

    return
          '( Scalar::Util::blessed(' 
        . $val
        . ') || ( '
        . " defined $val && ! ref $val ) )"
        . ' && List::MoreUtils::all { '
        . $val
        . '->can($_) } ' . '( '
        . ( join ', ', map { B::perlstring($_) } @{ $self->methods() } )
        . ')';
};

has '+inline_generator' => (
    init_arg => undef,
    default  => sub { $_inline_generator },
);

has '+message_generator' => (
    default => sub { $_[0]->_default_message_generator() },
);

__PACKAGE__->meta()->make_immutable();

1;
