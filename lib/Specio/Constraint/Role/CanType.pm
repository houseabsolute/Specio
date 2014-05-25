package Specio::Constraint::Role::CanType;

use strict;
use warnings;

use Lingua::EN::Inflect qw( PL_N WORDLIST );
use Scalar::Util qw( blessed );

use Moose::Role;

with 'Specio::Constraint::Role::Interface' =>
    { -excludes => [ '_attrs', '_wrap_message_generator' ] };

sub _wrap_message_generator {
    my $self      = shift;
    my $generator = shift;

    my @methods = @{ $self->methods() };

    $generator //= sub {
        my $description = shift;
        my $value       = shift;

        my $class = blessed $value;
        $class ||= $value;

        my @missing = grep { !$value->can($_) } @methods;

        my $noun = PL_N( 'method', scalar @missing );

        return
              $class
            . ' is missing the '
            . WORDLIST( map { "'$_'" } @missing ) . q{ }
            . $noun;
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

    $attrs->{methods} = {
        isa      => 'ArrayRef',
        required => 1,
    };

    return $attrs;
}

1;

# ABSTRACT: Provides a common implementation for Specio::Constraint::AnyCan and Specio::Constraint::ObjectCan

__END__

=head1 DESCRIPTION

See L<Specio::Constraint::AnyCan> and L<Specio::Constraint::ObjectCan> for details.
