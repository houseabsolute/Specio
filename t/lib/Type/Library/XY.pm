package Type::Library::XY;

use strict;
use warnings;

use parent 'Type::Exporter';

use Type::Declare;
use Type::Library::Builtins;

declare 'X',
    parent t('Str'),
    where { $_[0] =~ /x/ };

declare 'Y',
    parent t('X'),
    where { $_[0] =~ /y/ };

1;
