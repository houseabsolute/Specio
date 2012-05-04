package Type::Constraint::Role::IsaType;

use strict;
use warnings;

use Moose::Role;

with 'Type::Constraint::Role::Interface';

has class => (
    is       => 'ro',
    isa      => 'ClassName',
    required => 1,
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

sub _default_message_generator { return $_default_message_generator }

1;
