package Type::Library::Conflict;

use strict;
use warnings;

use parent 'Type::Exporter';

use Type::Declare;
use Type::Library::Builtins;

declare(
    'X',
    parent => t('Int'),
);

1;
