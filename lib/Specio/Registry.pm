package Specio::Registry;

use strict;
use warnings;

use parent 'Exporter';

our $VERSION = '0.52';

use Carp qw( confess croak );

our @EXPORT_OK
    = qw( exportable_types_for_package internal_types_for_package register );

my %Registry;

sub register {
    confess
        'register requires three or four arguments (package, name, type, [exportable])'
        unless @_ == 3 || @_ == 4;

    my $package    = shift;
    my $name       = shift;
    my $type       = shift;
    my $exportable = shift;

    croak "The $package package already has a type named $name"
        if $Registry{$package}{internal}{$name};

    # This is structured so that we can always return a _reference_ for
    # *_types_for_package. This means that the generated t sub sees any
    # changes to the registry as they happen. This is important inside a
    # package that is declaring new types. It needs to be able to see types it
    # has declared.
    $Registry{$package}{internal}{$name}   = $type;
    $Registry{$package}{exportable}{$name} = $type
        if $exportable;

    return;
}

sub exportable_types_for_package {
    my $package = shift;

    return $Registry{$package}{exportable} ||= {};
}

sub internal_types_for_package {
    my $package = shift;

    return $Registry{$package}{internal} ||= {};
}

1;

# ABSTRACT: Implements the per-package type registry

__END__

=pod

=for Pod::Coverage .*

=head1 DESCRIPTION

There's nothing public here.

=cut
