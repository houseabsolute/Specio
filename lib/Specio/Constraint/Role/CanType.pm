package Specio::Constraint::Role::CanType;

use strict;
use warnings;

our $VERSION = '0.31';

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

    my @methods = @{ $self->methods };

    unless ( defined $generator ) {
        $generator = sub {
            shift;
            my $value = shift;

            my $class = blessed $value;
            $class ||= $value;

            my @missing = grep { !$value->can($_) } @methods;

            my $noun = @missing == 1 ? 'method' : 'methods';
            my $list = _word_list( map {qq['$_']} @missing );

            return "$class is missing the $list $noun";
        };
    }

    my $d = $self->_description;

    return sub { $generator->( $d, @_ ) };
}
## use critic

sub _word_list {
    my @items = shift;

    return $items[0] if @items == 1;
    return join ' and ', @items if @items == 2;

    my $final = pop @items;
    my $list = join ', ', @items;
    $list .= ', and ' . $final;

    return $list;
}

1;

# ABSTRACT: Provides a common implementation for Specio::Constraint::AnyCan and Specio::Constraint::ObjectCan

__END__

=head1 DESCRIPTION

See L<Specio::Constraint::AnyCan> and L<Specio::Constraint::ObjectCan> for details.
