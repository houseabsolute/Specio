package Specio::Constraint::Role::DoesType;

use strict;
use warnings;

our $VERSION = '0.49';

use Clone               ();
use Scalar::Util        qw( blessed );
use Specio::PartialDump qw( partial_dump );

use Role::Tiny;

use Specio::Constraint::Role::Interface;
with 'Specio::Constraint::Role::Interface';

{
    ## no critic (Subroutines::ProtectPrivateSubs)
    my $attrs = Clone::clone( Specio::Constraint::Role::Interface::_attrs() );
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

    my $type          = ( split /::/, blessed $self )[-1];
    my $role          = $self->role;
    my $allow_classes = $self->_allow_classes;

    unless ( defined $generator ) {
        $generator = sub {
            shift;
            my $value = shift;

            return "An undef will never pass an $type check (wants $role)"
                unless defined $value;

            if ( ref $value && !blessed $value ) {
                my $dump = partial_dump($value);
                return
                    "An unblessed reference ($dump) will never pass an $type check (wants $role)";
            }

            if ( !blessed $value ) {
                return
                    "An empty string will never pass an $type check (wants $role)"
                    unless length $value;

                if (
                    $value =~ /\A
                        \s*
                        -?[0-9]+(?:\.[0-9]+)?
                        (?:[Ee][\-+]?[0-9]+)?
                        \s*
                        \z/xs
                ) {
                    return
                        "A number ($value) will never pass an $type check (wants $role)";
                }

                if ( !$allow_classes ) {
                    my $dump = partial_dump($value);
                    return
                        "A plain scalar ($dump) will never pass an $type check (wants $role)";
                }
            }

            my $got = blessed $value;
            $got ||= $value;

            return "The $got class does not consume the $role role";
        };
    }

    return sub { $generator->( undef, @_ ) };
}
## use critic

1;

# ABSTRACT: Provides a common implementation for Specio::Constraint::AnyDoes and Specio::Constraint::ObjectDoes

__END__

=head1 DESCRIPTION

See L<Specio::Constraint::AnyDoes> and L<Specio::Constraint::ObjectDoes> for
details.

