use strict;
use warnings;

package BAM {
    use Moo;
    use Types::Standard qw< InstanceOf Map Str Int >;
    use namespace::clean;

    use BAMSingleEnd;

    has file => (
        required => 1,
        is       => 'ro',
        isa      => sub { die "No such file '$_[0]' (or unreadable)" unless -r $_[0] },
    );

    has name => (
        is      => 'ro',
        default => sub { $_[0]->file },
    );

    has $_ => (
        is      => 'lazy',
        isa     => InstanceOf["BAMSingleEnd"],
    ) for qw(fwd rev);

    has _flagstat => (
        is  => 'lazy',
        isa => Map[Str, Int],
    );

    has parent => (
        is   => 'ro',
        isa  => InstanceOf["BAM", "FastQPE"],
    );

    with 'ParentComparators', 'MappedCount';

    sub _build_fwd { $_[0]->_build_single_end("fwd", @_) }
    sub _build_rev { $_[0]->_build_single_end("rev", @_) }
    sub _build_single_end {
        my ($self, $direction) = (@_);
        BAMSingleEnd->new(
            bam         => $self,
            direction   => $direction,
            read_count  => $self->_flagstat->{ {fwd => "read1", rev => "read2"}->{$direction} },
            ($self->parent
                ? (parent => $self->parent->$direction)
                : ()),
        );
    }

    sub _build__flagstat {
        my $self = shift;
        open my $stats, '-|', qw(samtools flagstat), $self->file
            or die "Cannot exec 'samtools flagstat ", $self->file, "': $!";

        # For example:
        #   1974148 + 0 in total (QC-passed reads + QC-failed reads)
        #   0 + 0 secondary
        #   0 + 0 supplimentary
        #   0 + 0 duplicates
        #   1430484 + 0 mapped (72.46%:-nan%)
        #   1974148 + 0 paired in sequencing
        #   987074 + 0 read1
        #   987074 + 0 read2
        #   ...
        my %count;
        while (<$stats>) {
            # Ignore QC-failed for now
            my ($qc_pass, $subset) = /^(\d+) [+] \d+ (?:in )?([\w -]+\w)/;
            $count{$subset} = $qc_pass;
        }
        return \%count;
    }

    sub read_count {
        $_[0]->_flagstat->{total}
    }

    sub read_count_tuple {
        ($_[0]->fwd->read_count, $_[0]->rev->read_count)
    }

    sub mapped_count {
        $_[0]->_flagstat->{mapped}
    }
}

1;
