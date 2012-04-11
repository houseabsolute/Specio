package Type::Constraint::ObjectIsa;

use strict;
use warnings;
use namespace::autoclean;

use B                  ();
use Devel::PartialDump ();
use Scalar::Util       ();
use Type::Library::Builtins;

use Moose;

with 'Type::Constraint::Interface';

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

my $_default_message_generator = sub {
    my $self  = shift;
    my $thing = shift;
    my $value = shift;

    return
          q{Validation failed for } 
        . $thing
        . q{ with value }
        . Devel::PartialDump->new()->dump($value)
        . '(not isa '
        . $self->class() . ')';
};

has '+message_generator' => (
    default => sub { $_default_message_generator },
);

has class => (
    is       => 'ro',
    isa      => 'ClassName',
    required => 1,
);

__PACKAGE__->meta()->make_immutable();

1;
