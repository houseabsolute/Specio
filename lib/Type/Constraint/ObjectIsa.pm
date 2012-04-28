package Type::Constraint::ObjectIsa;

use strict;
use warnings;
use namespace::autoclean;

use B                  ();
use Devel::PartialDump ();
use Scalar::Util       ();
use Type::Library::Builtins;

use Moose;

with 'Type::Constraint::Role::IsaType';

my $Object = t('Object');
has '+parent' => (
    init_arg => undef,
    default  => sub { $Object },
);

my $_inline_generator = sub {
    my $self = shift;
    my $val  = shift;

    return
          'Scalar::Util::blessed(' 
        . $val . ')' . ' && ' 
        . $val 
        . '->isa('
        . B::perlstring( $self->class ) . ')';
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
