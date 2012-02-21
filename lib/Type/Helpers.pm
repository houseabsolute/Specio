package Type::Helpers;

use strict;
use warnings;

use Carp qw( croak );
use Exporter 'import';
use overload ();
use Params::Util qw( _STRING );
use Scalar::Util qw( blessed );

our @EXPORT_OK = qw( install_t_sub _STRINGLIKE _INSTANCEDOES );

sub install_t_sub {
    my $caller = shift;
    my $types  = shift;

    my $t = sub {
        croak 'The t() subroutine requires a single non-empty string argument'
            unless _STRINGLIKE( $_[0] );

        croak "There is no type named $_[0] available for the $caller package"
            unless exists $types->{ $_[0] };

        return $types->{ $_[0] };
    };

    {
        no strict 'refs';
        no warnings 'redefine';
        *{ $caller . '::t' } = $t;
    }

    return;
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
