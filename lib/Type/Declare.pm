package Type::Declare;

use strict;
use warnings;

use parent 'Exporter';

use Carp qw( croak );
use Params::Util qw( _CODELIKE );
use Type::Constraint::Simple;
use Type::Helpers qw( install_t_sub _STRINGLIKE _INSTANCEDOES );
use Type::Registry qw( internal_types_for_package register );

our @EXPORT = qw( declare anon );

sub import {
    my $package = shift;

    my $caller = caller();

    $package->export_to_level( 1, $package, @_ );

    install_t_sub(
        $caller,
        internal_types_for_package($caller)
    );

    return;
}

sub declare {
    my $name = _STRINGLIKE(shift)
        or croak 'You must provide a name for declared types';
    my %p = @_;

    my $tc = _make_tc( name => $name, %p );

    register( scalar caller(), $name, $tc, 'exportable' );

    return;
}

sub anon {
    return _make_tc(@_);
}

sub _make_tc {
    my %p = @_;

    local $Carp::CarpLevel = $Carp::CarpLevel + 1;

    if ( exists $p{parent} ) {
        _INSTANCEDOES( $p{parent}, 'Type::Constraint::Interface' )
            or croak
            "The parent must be an object which does the Type::Constraint::Interface role, not a $p{parent}";
    }

    if ( exists $p{where} ) {
        _CODELIKE( $p{where} )
            or croak 'The where parameter must be a subroutine reference';
        $p{constraint} = delete $p{where};
    }

    if ( exists $p{message} ) {
        _CODELIKE( $p{message} )
            or croak 'The message parameter must be a subroutine reference';
        $p{message_generator} = delete $p{message};
    }

    if ( exists $p{inline} ) {
        _CODELIKE( $p{inline} )
            or croak 'The inline parameter must be a subroutine reference';
        $p{inline_generator} = delete $p{inline};
    }

    Type::Constraint::Simple->new(
        %p,
        declared_at => _declared_at(),
    );
}

sub _declared_at {
    my ( $package, $filename, $line, $sub ) = caller(2);

    return {
        package  => $package,
        filename => $filename,
        line     => $line,
        sub      => $sub,
    };
}

1;
