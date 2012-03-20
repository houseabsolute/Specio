package Type::Helpers;

use strict;
use warnings;

use Carp qw( croak );
use Exporter 'import';
use overload ();
use Params::Util qw( _STRING );
use Scalar::Util qw( blessed );

our @EXPORT_OK = qw( install_t_sub _INSTANCEDOES _STRINGLIKE _declared_at );

sub install_t_sub {
    my $caller = shift;
    my $types  = shift;

    my $t = sub {
        my $name = shift;

        croak 'The t() subroutine requires a single non-empty string argument'
            unless _STRINGLIKE( $name );

        croak "There is no type named $name available for the $caller package"
            unless exists $types->{ $name };

        my $found = $types->{ $name };

        return $found unless @_;

        my %p = @_;

        croak "Cannot parameterize a non-parameterizable type"
            unless $found->can('parameterize');

        return $found->parameterize(
            declared_at => _declared_at(),
            %p,
        );
    };

    {
        no strict 'refs';
        no warnings 'redefine';
        *{ $caller . '::t' } = $t;
    }

    return;
}

our $_CALLER_DEPTH = 2;

sub _declared_at {
    my $depth;
    my $sub_depth;
    if (@_) {
        $depth = $sub_depth = shift;
    }
    else {
        $depth = $_CALLER_DEPTH;

        # We want to skip the declare() and anon() subs that were exported to
        # the calling package from Type::Declare;
        $sub_depth = $depth + 1;
    }

    my ( $package, $filename, $line ) = caller($depth);

    my $sub = ( caller($sub_depth) )[3];

    return {
        package  => $package,
        filename => $filename,
        line     => $line,
        sub      => $sub,
    };
}

# XXX - this should be added to Params::Util
sub _STRINGLIKE ($) {
    return $_[0] if _STRING( $_[0] );

    return $_[0]
        if blessed $_[0]
            && overload::Method( $_[0], q{""} )
            && length "$_[0]";

    return undef;
}

sub _INSTANCEDOES ($$) {
    return $_[0]
        if blessed $_[0] && $_[0]->can('does') && $_[0]->does( $_[1] );
    return undef;
}

1;
