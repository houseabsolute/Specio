package Specio::Library::Builtins;

use strict;
use warnings;

use parent 'Specio::Exporter';

use Class::Load qw( is_class_loaded );
use overload ();
use re qw( is_regexp );
use Scalar::Util ();
use Specio::Constraint::Parameterizable;
use Specio::Declare;
use Sub::Quote qw( quote_sub quoted_from_sub );

declare(
    'Any',
    where => quote_sub(q{1}),
);

declare(
    'Item',
    where => quote_sub(q{1}),
);

declare(
    'Undef',
    parent => t('Item'),
    where  => quote_sub(q{!defined( $_[0] )}),
);

declare(
    'Defined',
    parent => t('Item'),
    where  => quote_sub(q{defined( $_[0] )}),
);

declare(
    'Bool',
    parent => t('Item'),
    where  => quote_sub(
              'Scalar::Util::blessed( $_[0] )' . ' ? '
            . ' overload::Overloaded( $_[0] )'
            . ' && defined overload::Method( $_[0], q{bool} )' . ' : ('
            . ' !defined( $_[0] )'
            . ' || $_[0] eq q{}'
            . ' || ( $_[0] eq q{1} )'
            . ' || ( $_[0] eq q{0} )' . ' )'
    ),
);

declare(
    'Value',
    parent => t('Defined'),
    where  => quote_sub(
        '( ' . t('Defined')->inline_check('embedded') . ' ) && !ref( $_[0] )'
    ),
);

declare(
    'Ref',
    parent => t('Defined'),

    # no need to call parent - ref also checks for definedness
    where => quote_sub('ref( $_[0] )'),
);

my $value_type = t('Value');
declare(
    'Str',
    parent => t('Value'),
    where  => quote_sub(
              'Scalar::Util::blessed( $_[0] )'
            . ' && overload::Overloaded( $_[0] )'
            . ' && defined overload::Method( $_[0], q{""} )'
            . ' ? 1 : ' . '( '
            . $value_type->inline_check('embedded') . ' )'
            . ' && ( ref( \\$_[0] ) eq q{SCALAR}'
            . '      || ref( \\(my $val = $_[0]) ) eq q{SCALAR} )'
    ),
);

declare(
    'Num',
    parent => t('Str'),
    where  => quote_sub(
              'Scalar::Util::blessed( $_[0] )'
            . ' ? overload::Overloaded( $_[0] )'
            . '   && defined overload::Method( $_[0], q{0+} )' . ' : '
            . '( '
            . $value_type->inline_check('embedded') . ' )'
            . ' && do { ( my $val = $_[0] ) =~ /\\A-?[0-9]+(?:\\.[0-9]+)?\\z/ }'
    ),
);

declare(
    'Int',
    parent => t('Num'),
    where  => quote_sub(
              'Scalar::Util::blessed( $_[0] )'
            . ' ? overload::Overloaded( $_[0] )'
            . '   && defined overload::Method( $_[0], q{0+} )'
            . '   && do { ( my $val = $_[0] + 0 ) =~ /\A-?[0-9]+\z/ }'
            . ' : ' . '( ( '
            . $value_type->inline_check( $_[0] ) . ')'
            . ' && do { ( my $val = $_[0] ) =~ /\A-?[0-9]+\z/; } )'
    ),
);

declare(
    'CodeRef',
    parent => t('Ref'),
    where  => quote_sub(
              'Scalar::Util::blessed( $_[0] )'
            . ' ? overload::Overloaded( $_[0] )'
            . '   && defined overload::Method( $_[0], q[&{}] )'
            . ' : ref( $_[0] ) eq q{CODE}'
    ),
);

declare(
    'RegexpRef',
    parent => t('Ref'),
    where  => quote_sub(
              'Scalar::Util::blessed( $_[0] )'
            . '    && overload::Overloaded( $_[0] )'
            . '    && defined overload::Method( $_[0], q{qr} )'
            . '|| re::is_regexp( $_[0] )'
    ),
);

declare(
    'GlobRef',
    parent => t('Ref'),
    where  => quote_sub(
              'Scalar::Util::blessed( $_[0] )'
            . ' ? overload::Overloaded( $_[0] )'
            . '   && defined overload::Method( $_[0], q[*{}] )'
            . ' : ref( $_[0] ) eq q{GLOB}'
    ),
);

# NOTE: scalar filehandles are GLOB refs, but a GLOB ref is not always a
# filehandle
declare(
    'FileHandle',
    parent => t('Ref'),
    where  => quote_sub(
              'Scalar::Util::blessed( $_[0] )'
            . ' ? $_[0]->isa( q{IO::Handle} )'
            . '   || ( overload::Overloaded( $_[0] )'
            . '        && defined overload::Method( $_[0], q[*{}] )'
            . '        && Scalar::Util::openhandle( *{ $_[0] } ) )'
            . ' : ref( $_[0] ) eq q{GLOB} '
            . '        && Scalar::Util::openhandle( $_[0] )'
    ),
);

declare(
    'Object',
    parent => t('Ref'),
    where  => quote_sub('Scalar::Util::blessed( $_[0] )'),
);

declare(
    'ClassName',
    parent => t('Str'),
    where  => quote_sub(
              '( '
            . t('Str')->inline_check('embedded') . ' )'
            . ' && defined( $_[0] )'
            . ' && Class::Load::is_class_loaded( "$_[0]" )'
    ),
);

declare(
    'ScalarRef',
    type_class => 'Specio::Constraint::Parameterizable',
    parent     => t('Ref'),
    where      => quote_sub(
              'Scalar::Util::blessed($_[0])'
            . ' ? overload::Overloaded( $_[0] )'
            . '   && defined overload::Method( $_[0], q[${}] )'
            . ' : ref( $_[0] ) eq q{SCALAR}'
            . '   || ref( $_[0] ) eq q{REF}'
    ),
    parameterized_inline_generator => sub {
        my $self      = shift;
        my $parameter = shift;

        my $container_quoted = quoted_from_sub( $self->_constraint() );
        my $parameter_quoted = quoted_from_sub( $parameter->_constraint() );

        return quote_sub(
            'do { '
                . $container_quoted->[1] . '}'
                . ' && do {'
                . 'local @_ = ( ${ $_[0] } );'
                . $parameter->inline_check('embedded') . '}',
            {
                %{ $container_quoted->[2] || {} },
                %{ $parameter_quoted->[2] || {} },
            },
        );
    },
);

declare(
    'ArrayRef',
    type_class => 'Specio::Constraint::Parameterizable',
    parent     => t('Ref'),
    where      => quote_sub(
              'Scalar::Util::blessed($_[0])'
            . ' ? overload::Overloaded( $_[0] )'
            . '   && defined overload::Method( $_[0], q[@{}] )'
            . ' : ref( $_[0] ) eq q{ARRAY}'
    ),
    parameterized_inline_generator => sub {
        my $self      = shift;
        my $parameter = shift;

        my $container_quoted = quoted_from_sub( $self->_constraint() );
        my $parameter_quoted = quoted_from_sub( $parameter->_constraint() );

        return quote_sub(
            'do { '
                . $container_quoted->[1] . '}'
                . ' && do {'
                . 'for my $member ( @{ $_[0] } ) {'
                . 'local @_ = $member;'
                . $parameter->inline_check('embedded') . '}' . '}',
            {
                %{ $container_quoted->[2] || {} },
                %{ $parameter_quoted->[2] || {} },
            },
        );
    },
);

declare(
    'HashRef',
    type_class => 'Specio::Constraint::Parameterizable',
    parent     => t('Ref'),
    where      => quote_sub(
              'Scalar::Util::blessed($_[0])'
            . ' ? overload::Overloaded( $_[0] )'
            . '   && defined overload::Method( $_[0], q[%{}] )'
            . ' : ref( $_[0] ) eq q{HASH}'
    ),
    parameterized_inline_generator => sub {
        my $self      = shift;
        my $parameter = shift;

        my $container_quoted = quoted_from_sub( $self->_constraint() );
        my $parameter_quoted = quoted_from_sub( $parameter->_constraint() );

        return quote_sub(
            'do { '
                . $container_quoted->[1] . '}'
                . ' && do {'
                . 'for my $member ( values %{ $_[0] } ) {'
                . 'local @_ = $member;'
                . $parameter->inline_check('embedded') . '}' . '}',
            {
                %{ $container_quoted->[2] || {} },
                %{ $parameter_quoted->[2] || {} },
            },
        );
    },
);

declare(
    'Maybe',
    type_class                     => 'Specio::Constraint::Parameterizable',
    parent                         => t('Item'),
    where                          => quote_sub('1'),
    parameterized_inline_generator => sub {
        my $self      = shift;
        my $parameter = shift;

        return
            '!defined( $_[0] ) || ( '
            . $parameter->inline_check('embedded') . ' )';
    },
);

1;

# ABSTRACT: Implements type constraint objects for Perl's built-in types

__END__

=head1 DESCRIPTION

See the documentation in L<Specio> for a list of types that this library
implements.

This library uses L<Specio::Exporter> to export its types.

