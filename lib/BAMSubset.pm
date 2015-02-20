use strict;
use warnings;

package BAMSubset {
    use Moo;
    use Types::Standard qw< InstanceOf Map Str Int Enum >;
    use String::ShellQuote qw< shell_quote >;
    use namespace::clean;

    has bam => (
        required => 1,
        is       => 'ro',
        isa      => InstanceOf["BAM"],
    );

    has name => (
        is      => 'ro',
        isa     => Str,
        default => sub { join ":", $_[0]->bam->name, "flags=" . $_[0]->flags },
    );

    has flags => (
        required => 1,
        is       => 'ro',
        isa      => Int,
    );

    has read_count => (
        required => 1,
        is       => 'lazy',
        isa      => Int,
    );

    has parent => (
        is   => 'ro',
        isa  => InstanceOf["BAMSubset", "FastQ"],
    );

    with 'ParentComparators';

    sub _build_read_count {
        my $self  = shift;
        my $file  = shell_quote($self->bam->file);
        my $flags = $self->flags;
        my $count = `samtools view -f $flags $file | wc -l`;
        chomp $count;
        return $count;
    }
}

1;
