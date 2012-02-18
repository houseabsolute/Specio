package Type::Registry;

use strict;
use warnings;

use parent 'Exporter';

use Carp qw( confess croak );

our @EXPORT_OK = qw( register types_for_package );

my %Registry;
sub register {
    confess 'register() requires three arguments (package, name, type)'
        unless @_ == 3;

    my $package = shift;
    my $name    = shift;
    my $type    = shift;

    my $existing = $Registry{$package}{$name};
    croak "The $package package already has a type named $name"
        if $existing && ! $existing->isa('Type::Constraint::Undeclared');

    $Registry{$package}{$name} = $type;

    return;
}

sub types_for_package {
    my $package = shift;

    return $Registry{$package} || {};
}

1;
