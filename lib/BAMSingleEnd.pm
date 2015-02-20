use strict;
use warnings;

package BAMSingleEnd {
    use Moo;
    use Types::Standard qw< InstanceOf Map Str Int Enum >;
    use String::ShellQuote qw< shell_quote >;
    use namespace::clean;

    extends 'BAMSubset';

    has direction => (
        required => 1,
        is       => 'ro',
        isa      => Enum[qw[fwd rev]],
    );

    has '+name' => (
        default => sub { join ":", $_[0]->bam->name, $_[0]->direction },
    );

    has '+flags' => (
        default => sub {
            0x1 | { fwd => 0x40, rev => 0x80 }->{$_[0]->direction}
        },
    );

    has '+parent' => (
        # More restrictive than BAMSubset
        isa => InstanceOf["BAMSingleEnd", "FastQ"],
    );

    has mapped => (
        is  => 'lazy',
        isa => InstanceOf["BAMSubset"],
    );

    with 'Mapped';

    sub _build_mapped {
        my $unmapped = `samtools view -f $flags $file | wc -l`;
        return $self->read_count - $unmapped;

        my $flags = 0x1 | 0x4 | { fwd => 0x40, rev => 0x80 }->{$self->direction};

        my $self  = shift;
        BAMSubset->new(
            bam     => $self->bam,
            flags   => $
            parent  => 
            read_count  => $self->_flagstat->{ {fwd => "read1", rev => "read2"}->{$direction} },
            ($self->parent
                ? (parent => $self->parent->$direction)
                : ()),
        );
    }
}

1;
