use strict;
use warnings;

package ParentComparators {
    use Moo::Role;

    requires 'parent';
    requires 'read_count';

    sub percentage_of_parent {
        $_[0]->read_count / $_[0]->parent->read_count * 100
    }

    sub discarded_read_count {
        $_[0]->parent->read_count - $_[0]->read_count
    }

    sub discarded_percentage_of_parent {
        $_[0]->discarded_read_count / $_[0]->parent->read_count * 100
    }
}

1;
