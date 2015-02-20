use strict;
use warnings;

package BAMSingleEnd {
    use Moo;
    use Types::Standard qw< InstanceOf Map Str Int Enum >;
    use String::ShellQuote qw< shell_quote >;
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

    has mapped_count => (
        is  => 'lazy',
        isa => Int,
    );

    has parent => (
        is   => 'ro',
        isa  => InstanceOf["BAMSingleEnd", "FastQ"],
    );

    with 'ParentComparators', 'MappedCount';

    sub _build_mapped_count {
        my $self  = shift;
        my $file  = shell_quote($self->bam->file);
        my $flags = 0x1 | 0x4 | { fwd => 0x40, rev => 0x80 }->{$self->direction};
        my $unmapped = `samtools view -f $flags $file | wc -l`;
        return $self->read_count - $unmapped;
    }
}

1;
