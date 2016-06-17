package Specio::Constraint::Role::IsaType;

use strict;
use warnings;

our $VERSION = '0.20';

use Specio::PartialDump qw( partial_dump );
use Storable qw( dclone );

use Role::Tiny;

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

    $attrs->{class} = {
        isa      => 'ClassName',
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

    my $class = $self->class;

    unless ( defined $generator ) {
        $generator = sub {
            my $description = shift;
            my $value       = shift;

            return
                  "Validation failed for $description with value "
                . partial_dump($value)
                . '(not isa '
                . $class . ')';
        };
    }

    my $d = $self->_description;

    return sub { $generator->( $d, @_ ) };
}
## use critic

1;

# ABSTRACT: Provides a common implementation for Specio::Constraint::AnyIsa and Specio::Constraint::ObjectIsa

__END__

=head1 DESCRIPTION

See L<Specio::Constraint::AnyIsa> and L<Specio::Constraint::ObjectIsa> for details.
