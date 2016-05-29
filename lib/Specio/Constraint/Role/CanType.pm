package Specio::Constraint::Role::CanType;

use strict;
use warnings;

our $VERSION = '0.15';

use Lingua::EN::Inflect qw( PL_N WORDLIST );
use Scalar::Util qw( blessed );
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

    $attrs->{methods} = {
        isa      => 'ArrayRef',
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

    my @methods = @{ $self->methods() };

    $generator //= sub {
        shift;
        my $value = shift;

        my $class = blessed $value;
        $class ||= $value;

        my @missing = grep { !$value->can($_) } @methods;

        my $noun = PL_N( 'method', scalar @missing );

        return
              $class
            . ' is missing the '
            . WORDLIST( map {"'$_'"} @missing ) . q{ }
            . $noun;
    };

    my $d = $self->_description();

    return sub { $generator->( $d, @_ ) };
}
## use critic

1;

# ABSTRACT: Provides a common implementation for Specio::Constraint::AnyCan and Specio::Constraint::ObjectCan

__END__

=head1 DESCRIPTION

See L<Specio::Constraint::AnyCan> and L<Specio::Constraint::ObjectCan> for details.
