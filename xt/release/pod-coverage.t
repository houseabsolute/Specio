use strict;
use warnings;

use Pod::Coverage::Moose;
use Test::Pod::Coverage;
use Test::More;

my %skip = map { $_ => 1 } qw( Type::Helpers Type::Registry );

# This is a stripped down version of all_pod_coverage_ok which lets us
# vary the trustme parameter per module.
my @modules = grep { !$skip{$_} } all_modules();
plan tests => scalar @modules;

my %trustme = (
    'Type::Coercion' => ['BUILD'],
);

for my $module ( sort @modules ) {
    my $trustme = [];

    if ( $trustme{$module} ) {
        my $methods = join '|', @{ $trustme{$module} };
        $trustme = [qr/^(?:$methods)$/];
    }

    pod_coverage_ok(
        $module,
        {
            coverage_class => 'Pod::Coverage::Moose',
            trustme        => $trustme,
        },
        "Pod coverage for $module"
    );
}

done_testing();
