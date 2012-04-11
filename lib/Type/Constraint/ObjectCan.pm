package Type::Constraint::ObjectCan;

use strict;
use warnings;
use namespace::autoclean;

use B ();
use Lingua::EN::Inflect qw( PL_N WORDLIST );
use Scalar::Util qw( blessed );
use Type::Library::Builtins;

use Moose;

with 'Type::Constraint::Interface';

my $Object = t('Object');
has '+parent' => (
    init_arg => undef,
    default  => sub { $Object },
);

my $_inline_generator = sub {
    my $self = shift;
    my $val  = shift;

    return
          'Scalar::Util::blessed(' 
        . $val . ')'
        . ' && List::MoreUtils::all { '
        . $val
        . '->can($_) } ' . '( '
        . ( join ', ', map { B::perlstring($_) } @{ $self->methods() } ) . ')';
};

has '+inline_generator' => (
    init_arg => undef,
    default  => sub { $_inline_generator },
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

has '+message_generator' => (
    default => sub { $_default_message_generator },
);

has methods => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

override BUILDARGS => sub {
    my $self = shift;

    my $p = super();

    if ( defined $p->{can} && !ref $p->{can} ) {
        $p->{can} = [ $p->{can} ];
    }

    return $p;
};

__PACKAGE__->meta()->make_immutable();

1;
