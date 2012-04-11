package Type::Declare;

use strict;
use warnings;

use parent 'Exporter';

use Carp qw( croak );
use Params::Util qw( _CODELIKE );
use Type::Constraint::Simple;
use Type::Helpers qw( install_t_sub _INSTANCEDOES _STRINGLIKE _declared_at );
use Type::Registry qw( internal_types_for_package register );

our @EXPORT = qw( anon declare enum object_can_type object_isa_type );

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

    return $tc;
}

sub anon {
    return _make_tc(@_);
}

sub _make_tc {
    my %p = @_;

    my $class = delete $p{type_class} || 'Type::Constraint::Simple';

    return $class->new(
        %p,
        declared_at => _declared_at(),
    );
}

sub object_can_type {
    my $name;
    $name = shift if @_ % 2;
    my %p = @_;

    # This cannot be loaded earlier, since it loads Type::Library::Builtins,
    # which in turn wants to load Type::Declare (the current module).
    require Type::Constraint::ObjectCan;

    my $tc = _make_tc(
        ( defined $name ? ( name => $name ) : () ),
        methods    => $p{methods},
        type_class => 'Type::Constraint::ObjectCan',
    );

    register( scalar caller(), $name, $tc, 'exportable' )
        if defined $name;

    return $tc;
}

sub object_isa_type {
    my $name = shift;
    my $isa = shift || $name;

    require Type::Constraint::ObjectIsa;

    my $tc = _make_tc(
        name       => $name,
        class      => $isa,
        type_class => 'Type::Constraint::ObjectIsa',
    );

    register( scalar caller(), $name, $tc, 'exportable' );

    return $tc;
}

1;
