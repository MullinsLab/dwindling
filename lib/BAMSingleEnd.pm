use strict;
use warnings;

package BAMSingleEnd {
    use Moo;
    use Types::Standard qw< InstanceOf Map Str Int Enum >;
    use namespace::clean;

    has bam => (
        required => 1,
        is       => 'ro',
        isa      => InstanceOf["BAM"],
    );

    has direction => (
        required => 1,
        is       => 'ro',
        isa      => Enum[qw[fwd rev]],
    );

    has name => (
        is      => 'ro',
        default => sub { join ":", $_[0]->bam->name, $_[0]->direction },
    );

    has read_count => (
        required => 1,
        is       => 'ro',
        isa      => Int,
    );

    has parent => (
        is   => 'ro',
        isa  => InstanceOf["BAMSingleEnd", "FastQ"],
    );

    with 'ParentComparators';
}

1;
