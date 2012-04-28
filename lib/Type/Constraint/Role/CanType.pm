package Type::Constraint::Role::CanType;

use strict;
use warnings;

use Lingua::EN::Inflect qw( PL_N WORDLIST );
use Scalar::Util qw( blessed );

use Moose::Role;

with 'Type::Constraint::Interface';

has methods => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

my $_default_message_generator = sub {
    my $self  = shift;
    my $thing = shift;
    my $value = shift;

    my @methods = grep { !$value->can($_) } @{ $self->methods() };
    my $class = blessed $value;
    $class ||= $value;

    my $noun = PL_N( 'method', scalar @methods );

    return
          $class
        . ' is missing the '
        . WORDLIST( map { "'$_'" } @methods ) . q{ }
        . $noun;
};

sub _default_message_generator { return $_default_message_generator }

override BUILDARGS => sub {
    my $self = shift;

    my $p = super();

    if ( defined $p->{can} && !ref $p->{can} ) {
        $p->{can} = [ $p->{can} ];
    }

    return $p;
};

1;
