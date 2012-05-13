package Type::Constraint::Simple;

use strict;
use warnings;
use namespace::autoclean;

use Moose;

with 'Type::Constraint::Role::Interface';

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Class for simple (non-parameterized or specialized) types

__END__

=head1 SYNOPSIS

  my $tc = Type::Constraint::Simple
