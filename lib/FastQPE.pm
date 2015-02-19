use strict;
use warnings;

package FastQPE {
    use Moo;
    use Types::Standard qw< InstanceOf Int >;
    use namespace::clean;

    use FastQ;

    has name => (
        required => 1,
        is       => 'ro',
    );

    has $_ => (
        required => ($_ ne "orphans" ? 1 : 0),
        is       => 'ro',
        isa      => InstanceOf["FastQ"],
    ) for qw(fwd rev orphans);

    has read_count => (
        is  => 'lazy',
        isa => Int,
    );

    has parent => (
        is   => 'ro',
        isa  => InstanceOf["FastQPE"],
    );

    with 'ParentComparators';

    sub _build_read_count {
        $_[0]->fwd->read_count + $_[0]->rev->read_count
    }

    sub BUILDARGS {
        my $self = shift;
        my $args = $self->next::method(@_);

        # Coerce fwd/rev/orphans from strings (filenames) into FastQ objects,
        # optionally propogating parents.
        for my $fq (qw(fwd rev orphans)) {
            next if not defined $args->{$fq}
                 or ref $args->{$fq};

            my %fastq = (
                name => join(":", $args->{name}, $args->{$fq}),
                file => $args->{$fq},
            );
            if (my $parent = $args->{parent}) {
                $fastq{parent} = $fq eq 'orphans'
                    ? $parent
                    : $parent->$fq;
            }
            $args->{$fq} = FastQ->new(%fastq);
        }
        return $args;
    }

    sub read_count_tuple {
        ($_[0]->fwd->read_count, $_[0]->rev->read_count)
    }
}

1;
