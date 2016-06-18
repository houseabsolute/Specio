package Specio::TypeChecks;

use strict;
use warnings;

our $VERSION = '0.23';

use Exporter qw( import );
use Specio::Helpers qw( is_class_loaded );
use Scalar::Util qw( blessed );

our @EXPORT_OK = qw(
    does_role
    is_ArrayRef
    is_ClassName
    is_CodeRef
    is_HashRef
    is_Int
    is_Str
    isa_class
);

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
    is_class_loaded( $_[0] );
}

sub isa_class {
    blessed( $_[0] ) && $_[0]->isa( $_[1] );
}

sub does_role {
    blessed( $_[0] ) && $_[0]->can('does') && $_[0]->does( $_[1] );
}

1;

# ABSTRACT: Type checks used internally for Specio classes (it's not self-bootstrapping (yet?))

__END__

=pod

=for Pod::Coverage .*

=head1 DESCRIPTION

There's nothing public here.

=cut
