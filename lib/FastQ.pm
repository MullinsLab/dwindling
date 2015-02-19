use strict;
use warnings;

package FastQ {
    use Moo;
    use Types::Standard qw< InstanceOf Int >;
    use String::ShellQuote qw< shell_quote >;
    use namespace::clean;

    has file => (
        required => 1,
        is       => 'ro',
        isa      => sub { die "No such file '$_[0]' (or unreadable)" unless -r $_[0] },
    );

    has name => (
        is      => 'ro',
        default => sub { $_[0]->file },
    );

    has read_count => (
        is  => 'lazy',
        isa => Int,
    );

    has parent => (
        is   => 'ro',
        isa  => InstanceOf["FastQ", "FastQPE"],
    );

    with 'ParentComparators';

    sub _build_read_count {
        my $self  = shift;
        my $file  = shell_quote($self->file);
        my $lines = `zcat -f $file | wc -l`;
        chomp $lines;

        die "Malformed FastQ @{[$self->file]}?  Lines ($lines) is not divisible by 4."
            unless $lines % 4 == 0;
        return $lines / 4;
    }
}

1;
