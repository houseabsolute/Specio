package Specio::Exception;

use strict;
use warnings;

use overload
    q{""}    => 'as_string',
    fallback => 1;

use Devel::StackTrace;
use Scalar::Util qw( blessed );
use Specio::OO qw( _specio_BUILDARGS );

sub new {
    my $class = shift;
    my $p     = $class->_specio_BUILDARGS(
        $class->_attrs(),
        @_,
    );

    $p->{stack_trace} = Devel::StackTrace->new();

    return bless $p, $class;
}

sub _attrs {
    my $class = shift;

    return [
        {
            name     => 'message',
            isa      => 'Str',
            required => 1,
        },
        {
            name     => 'type',
            does     => 'Specio::Constraint::Role::Interface',
            required => 1,
        },
        {
            name     => 'value',
            required => 1,
        },
    ];
}

sub as_string {
    my $self = shift;

    my $str = $self->message();
    $str .= "\n\n" . $self->stack_trace()->as_string();

    return $str;
}

sub message { $_[0]->{message} }

sub stack_trace { $_[0]->{stack_trace} }

sub throw {
    my $self = shift;

    die $self if blessed $self;

    die $self->new(@_);
}

1;

# ABSTRACT: A Throwable::Error subclass for type constraint failures

__END__

=pod

=head1 DESCRIPTION

  use Try::Tiny;

  try {
      $type->validate_or_die($value);
  }
  catch {
      if ( $_->isa('Specio::Exception') ) {
          print $_->message(), "\n";
          print $_->type()->name(), "\n";
          print $_->value(), "\n";
      }
  };

=head1 DESCRIPTION

This is a subclass of L<Throwable::Error> which adds a few additional
attributes specific to type constraint failures.

=head1 API

The two attributes it adds are C<type> and C<value>, both of which are
required. The C<type> must be an object which does the
L<Specio::Constraint::Role::Interface> role and the C<value> can be anything
(including C<undef>).

=cut
