package Specio::Constraint::Role::DoesType;

use strict;
use warnings;

our $VERSION = '0.18';

use Role::Tiny;
use Storable qw( dclone );

use Specio::Constraint::Role::Interface;
with 'Specio::Constraint::Role::Interface';

{
    ## no critic (Subroutines::ProtectPrivateSubs)
    my $attrs = dclone( Specio::Constraint::Role::Interface::_attrs() );
    ## use critic

    for my $name (qw( parent _inline_generator )) {
        $attrs->{$name}{init_arg} = undef;
        $attrs->{$name}{builder}
            = $name =~ /^_/ ? '_build' . $name : '_build_' . $name;
    }

    $attrs->{role} = {
        isa      => 'Str',
        required => 1,
    };

    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    sub _attrs {
        return $attrs;
    }
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _wrap_message_generator {
    my $self      = shift;
    my $generator = shift;

    my $role = $self->role;

    $generator //= sub {
        my $description = shift;
        my $value       = shift;

        return
              "Validation failed for $description with value "
            . Devel::PartialDump->new->dump($value)
            . '(does not do '
            . $role . ')';
    };

    my $d = $self->_description;

    return sub { $generator->( $d, @_ ) };
}
## use critic

1;

# ABSTRACT: Provides a common implementation for Specio::Constraint::AnyDoes and Specio::Constraint::ObjectDoes

__END__

=head1 DESCRIPTION

See L<Specio::Constraint::AnyDoes> and L<Specio::Constraint::ObjectDoes> for
details.
