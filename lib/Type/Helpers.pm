package Type::Helpers;

use strict;
use warnings;

use Carp qw( croak );
use Exporter 'import';
use overload ();
use Params::Util qw( _STRING );
use Scalar::Util qw( blessed );

our @EXPORT_OK = qw( install_t_sub );

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
    return 1 if _STRING( $_[0] );

    return 1
        if blessed $_[0]
            && overload::Method( $_[0], q{""} )
            && length "$_[0]";

    return 0;
}

1;
