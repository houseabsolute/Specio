package Specio::OO;

use strict;
use warnings;

use Carp qw( confess );
use Exporter qw( import );
use Module::Runtime qw( is_module_name );
use Scalar::Util qw( blessed weaken );

our @EXPORT_OK = qw(
    new
    _accessorize
    is_ArrayRef
    is_HashRef
    is_CodeRef
    is_Str
    does_role
    _attr_to_hashref
);

sub new {
    my $class = shift;

    my $p = _BUILDARGS( $class, @_ );

    my $self = bless $p, $class;

    #XXX - Moose::Object
    if ( $self->can('BUILDALL') ) {
        $self->BUILDALL();
    }
    else {
        _BUILDALL($self);
    }

    return $self;
}

sub _BUILDARGS {
    my $class = shift;

    local $Carp::CarpLevel = $Carp::CarpLevel + 1;

    my %p = _validate_args( $class, @_ );

    for my $attr ( @{ _attrs($class) } ) {
        my $key_name = $attr->{init_arg} // $attr->{name};
        if ( $attr->{required} ) {
            _constructor_confess(
                "$class->new() requires a $key_name argument.")
                unless exists $p{$key_name};
        }

        if ( $attr->{builder} && !$attr->{lazy} && !exists $p{$key_name} ) {
            my $builder = $attr->{builder};
            $p{$key_name} = $class->$builder();
        }

        next unless exists $p{$key_name};

        if ( $attr->{isa} ) {
            my $validator = __PACKAGE__->can( 'is_' . $attr->{isa} );
            $validator ||= sub { isa_class( @_, $attr->{isa} ); };

            $validator->( $p{$key_name} )
                or confess _bad_value_message(
                "The value you provided to $class->new() for $key_name is not a valid $attr->{isa}.",
                $p{$key_name},
                );
        }

        if ( $attr->{does} ) {
            does_role( $p{$key_name}, $attr->{does} )
                or confess _bad_value_message(
                "The value you provided to $class->new() for $key_name does not do the $attr->{does} role.",
                $p{$key_name},
                );
        }

        $p{ $attr->{name} } = delete $p{$key_name};

        if ( $attr->{weak_ref} ) {
            weaken $p{ $attr->{name} };
        }
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

sub _bad_value_message {
    my $message = shift;
    my $value   = shift;

    return
          $message
        . ' You passed '
        . Devel::PartialDump->new()->dump($value);
}

sub _BUILDALL {
    my $self = shift;

    for my $class ( @{ mro::get_linear_isa( ref $self ) } ) {
        my $build = do {
            no strict 'refs';
            \&{ $class . '::BUILD' };
        };

        next unless $build;

        $self->$build();
    }
}

sub _accessorize {
    my $class = shift;

    for my $attr ( @{ _attrs($class) } ) {
        my $name = $attr->{name};

        my $reader;
        if ( $attr->{lazy} && ( my $builder = $attr->{builder} ) ) {
            $reader = sub {
                $_[0]->{$name} ||= $_[0]->$builder();
            };
        }
        else {
            $reader = sub { $_[0]->{$name} };
        }

        unless ( $class->can($name) ) {
            no strict 'refs';
            *{ $class . '::' . $name } = $reader;
        }

        next unless $attr->{predicate};

        my $predicate = sub { exists $_[0]->{$name} };

        unless ( $class->can( $attr->{predicate} ) ) {
            no strict 'refs';
            *{ $class . '::' . $attr->{predicate} } = $predicate;
        }
    }
}

sub _attrs {
    my $class = shift;

    return $class->_attrs() if $class->can('_attrs');

    return [ map { _attr_to_hashref($_) }
            $class->meta()->get_all_attributes() ];
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

sub is_Int {
    ( defined( $_[0] ) && !ref( $_[0] ) && ref( \$_[0] ) eq 'SCALAR'
            || ref( \( my $val = $_[0] ) eq 'SCALAR' ) )
        && $_[0] =~ /^[0-9]+$/;
}

sub is_ClassName {
    is_module_name( $_[0] );
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
        if (
            $attr->type_constraint()->isa('Moose::Meta::TypeConstraint::Role')
            ) {
            $h{does} = $attr->type_constraint()->role();
        }
        else {
            $h{isa} = $attr->type_constraint()->name();
        }
    }

    if ( $attr->has_builder() ) {
        $h{builder} = $attr->builder();
    }

    if ( $attr->has_predicate() ) {
        $h{predicate} = $attr->predicate();
    }

    $h{lazy} = $attr->is_lazy();

    $h{weak_ref} = $attr->is_weak_ref();

    die $attr->associated_class->name . ' - ' . $attr->name . ' has default'
        if $attr->has_default();

    return \%h;
}

1;

