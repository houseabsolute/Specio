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
    my $type  = shift;
    my $value = shift;

    return
          q{Validation failed for } 
        . $type->_description()
        . q{ with value }
        . Devel::PartialDump->new()->dump($value)
        . '(not isa '
        . $type->class() . ')';
};

sub _default_message_generator { return $_default_message_generator }

1;

# ABSTRACT: Provides a common implementation for Type::Constraint::AnyIsa and Type::Constraint::ObjectIsa

__END__

=head1 DESCRIPTION

See L<Type::Constraint::AnyIsa> and L<Type::Constraint::ObjectIsa> for details.
