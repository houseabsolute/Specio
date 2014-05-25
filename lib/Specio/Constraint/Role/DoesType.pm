package Specio::Constraint::Role::DoesType;

use strict;
use warnings;

use Moose::Role;

with 'Specio::Constraint::Role::Interface' =>
    { -excludes => [ '_attrs', '_wrap_message_generator' ] };

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

sub _attrs {
    my $role_attrs = Specio::Constraint::Role::Interface::_attrs();

    my %self_attrs = map { $_->name() => Specio::OO::_attr_to_hashref($_) }
        map { __PACKAGE__->meta()->get_attribute($_) }
        __PACKAGE__->meta()->get_attribute_list();

    my $attrs = {
        %{$role_attrs},
        %self_attrs,
    };

    for my $name (qw( parent _inline_generator )) {
        $attrs->{$name}{init_arg} = undef;
        $attrs->{$name}{builder} = '_build_' . ( $name =~ s/^_//r );
    }

    $attrs->{role} = {
        isa      => 'Str',
        required => 1,
    };

    return $attrs;
}

1;

# ABSTRACT: Provides a common implementation for Specio::Constraint::AnyDoes and Specio::Constraint::ObjectDoes

__END__

=head1 DESCRIPTION

See L<Specio::Constraint::AnyDoes> and L<Specio::Constraint::ObjectDoes> for
details.
