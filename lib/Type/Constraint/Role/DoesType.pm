package Type::Constraint::Role::DoesType;

use strict;
use warnings;

use Moose::Role;

with 'Type::Constraint::Role::Interface' =>
    { -excludes => ['_wrap_message_generator'] };

has role => (
    is => 'ro',
    # XXX - we can't use Moose's RoleName since that restricts this
    # to only Moose roles.
    isa      => 'Str',
    required => 1,
);

sub _wrap_message_generator {
    my $self      = shift;
    my $generator = shift;

    my $role = $self->role();

    $generator //= sub {
        my $description = shift;
        my $value       = shift;

        return
              "Validation failed for $description with value "
            . Devel::PartialDump->new()->dump($value)
            . '(does not do '
            . $role . ')';
    };

    my $d = $self->_description();

    return sub { $generator->( $d, @_ ) };
}

1;

# ABSTRACT: Provides a common implementation for Type::Constraint::AnyDoes and Type::Constraint::ObjectDoes

__END__

=head1 DESCRIPTION

See L<Type::Constraint::AnyDoes> and L<Type::Constraint::ObjectDoes> for
details.
