package Specio::OO;

use strict;
use warnings;

use Carp qw( confess );
use Exporter qw( import );
use Scalar::Util qw( blessed weaken );
use Specio::TypeChecks qw(
    does_role
    is_ArrayRef
    is_ClassName
    is_CodeRef
    is_HashRef
    is_Int
    is_Str
    isa_class
);
use Storable qw( dclone );

our @EXPORT_OK = qw(
    new
    clone
    _accessorize
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

    my $attrs = $class->_attrs();
    for my $name ( sort keys %{$attrs} ) {
        my $attr = $attrs->{$name};
        my $key_name = $attr->{init_arg} // $name;

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

        $p{$name} = delete $p{$key_name};

        if ( $attr->{weak_ref} ) {
            weaken $p{$name};
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
            defined &{ $class . '::BUILD' }
                ? \&{ $class . '::BUILD' }
                : undef;
        };

        next unless $build;

        $self->$build();
    }
}

sub _accessorize {
    my $class = shift;

    my $attrs = $class->_attrs();
    for my $name ( sort keys %{$attrs} ) {
        my $attr = $attrs->{$name};

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

sub clone {
    my $self = shift;

    my %new;
    for my $key ( keys %{$self} ) {
        my $value = $self->{$key};

        $new{$key}
            = blessed $value           ? $value->clone()
            : ( ref $value eq 'CODE' ) ? $value
            : ref $value               ? dclone($value)
            :                            $value;
    }

    return bless \%new, ( ref $self );
}

1;

