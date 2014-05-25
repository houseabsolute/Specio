package Specio::OO;

use strict;
use warnings;

use Carp qw( confess );
use Exporter qw( import );
use Scalar::Util qw( blessed );

our @EXPORT_OK = qw(
    _specio_BUILDARGS
    is_ArrayRef
    is_HashRef
    is_CodeRef
    is_Str
    does_role
    _attr_to_hashref
);

sub _specio_BUILDARGS {
    my $class      = shift;
    my $definition = shift;

    local $Carp::CarpLevel = $Carp::CarpLevel + 1;

    my %p = _validate_args( $class, @_ );

    for my $attr ( @{$definition} ) {
        my $key_name = $attr->{init_arg} // $attr->{name};
        if ( $attr->{required} ) {
            _constructor_confess(
                "$class->new() requires a $key_name argument.")
                unless exists $p{$key_name};
        }

        next unless exists $p{$key_name};

        if ( $attr->{isa} ) {
            my $validator = __PACKAGE__->can( 'is_' . $attr->{isa} );
            $validator ||= sub { isa_class( @_, $attr->{isa} ); };

            $validator->( $p{$key_name} )
                or confess
                "The value you provided for $key_name is not a valid $attr->{isa}";
        }

        if ( $attr->{does} ) {
            does_role( $p{$key_name}, $attr->{does} )
                or confess
                "The value you provided for $key_name does not do the $attr->{does} role";
        }

        $p{ $attr->{name} } = delete $p{$key_name};
    }

    return \%p;
}

sub _validate_args {
    my $class = shift;

    local $Carp::CarpLevel = $Carp::CarpLevel + 1;

    if ( @_ == 1 ) {
        if ( ref $_[0] eq 'HASH' ) {
            return %{ shift() };
        }
        else {
            _constructor_confess( _bad_args_message( $class, @_ ) );
        }
    }
    else {
        _constructor_confess( _bad_args_message( $class, @_ ) ) if @_ % 2;
        return @_;
    }
}

sub _constructor_confess {
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    confess shift;
}

sub _bad_args_message {
    my $class = shift;

    return
        "$class->new() requires either a hashref or hash as arguments. You passed "
        . Devel::PartialDump->new()->dump(@_);
}

sub is_ArrayRef {
    return ref $_[0] eq 'ARRAY';
}

sub is_CodeRef {
    return ref $_[0] eq 'CODE';
}

sub is_HashRef {
    return ref $_[0] eq 'HASH';
}

sub is_Str {
    defined( $_[0] ) && !ref( $_[0] ) && ref( \$_[0] ) eq 'SCALAR'
        || ref( \( my $val = $_[0] ) eq 'SCALAR' );
}

sub isa_class {
    blessed( $_[0] ) && $_[0]->isa( $_[1] );
}

sub does_role {
    blessed( $_[0] ) && $_[0]->can('does') && $_[0]->does( $_[1] );
}

sub _attr_to_hashref {
    my $attr = shift;

    my %h = (
        name     => $attr->name(),
        init_arg => $attr->init_arg(),
    );

    if ( $attr->has_type_constraint() ) {
        if ( $attr->type_constraint()->isa('Moose::Meta::TypeConstraint::Role') ) {
            $h{does} = $attr->type_constraint()->role();
        }
        else {
            $h{isa} = $attr->type_constraint()->name();
        }
    }

    return \%h;
}

1;

