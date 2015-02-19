use strict;
use warnings;

package App::Dwindling {
    use FastQPE;
    use List::MoreUtils qw< part >;
    use base 'Exporter::Tiny';
    our @EXPORT = qw( parse_args stages_from stages_to_text stages_to_csv );

    sub parse_args {
        my @args = @_;
        unshift @args, ':::'
            unless ($args[0] || '') eq ':::'
                or not @args;

        # Partition into (undef, [:::, fwd, rev], [:::, ...])
        my $index = 0;
        @args = part {
            ($_ eq ':::' ? ++$index : $index) - 1
        } @args;

        # Remove first element (:::) from each stage arrayref
        splice(@$_, 0, 1) for @args;
        return @args;
    }

    sub stages_from {
        my @stages;
        for my $stage (@_) {
            my ($name, $fwd, $rev, $orphans) = @$stage;
            push @stages, FastQPE->new(
                name    => $name,
                fwd     => $fwd,
                rev     => $rev,
                (defined $orphans
                    ? (orphans => $orphans)
                    : ()),
                ($stages[-1]
                    ? (parent => $stages[-1])
                    : ()),
            );
        }
        return @stages;
    }

    sub stages_to_text {
        my $count = 0;
        for my $stage (@_) {
            print "\n" if $count++;

            my $width = length $stage->read_count;

            # Basic counts and percentages
            printf '%*d %s = %d forward + %d reverse',
                $width,
                $stage->read_count,
                $stage->name,
                $stage->read_count_tuple;

            if ($stage->parent) {
                printf ' (= %0.2f%% of %s)',
                    $stage->percentage_of_parent,
                    $stage->parent->name;
            }
            print "\n";

            # Orphans
            if ($stage->orphans) {
                printf '%*d single-end orphans',
                    $width, $stage->orphans->read_count;
                if ($stage->parent) {
                    printf ' (= %0.2f%% of %s)',
                        $stage->orphans->percentage_of_parent,
                        $stage->orphans->parent->name;
                }
                print "\n";
            }

            # Discarded
            if ($stage->parent) {
                printf '%*d discarded%s (= %0.2f%% of %s)'."\n",
                    $width,
                    $stage->discarded_read_count,
                    ($stage->orphans ? ", including orphans" : ""),
                    $stage->discarded_percentage_of_parent,
                    $stage->parent->name;
            }
        }
    }

    sub stages_to_csv {
        require Text::CSV;
        my $csv = Text::CSV->new({ binary => 1, eol => $/ })
            or die "Cannot use CSV: ", Text::CSV->error_diag;
        my $out = \*STDOUT;

        $csv->print($out, [qw(stage type count parent_stage percentage_of_parent discarded_from_parent)]);
        for my $stage (@_) {
            for my $type ("total", "fwd", "rev", "orphans") {
                my $subset = $type eq "total" ? $stage : $stage->$type
                    or next;
                $csv->print($out, [
                    $stage->name,
                    $type,
                    $subset->read_count,
                    ($subset->parent
                        ? ($subset->parent->name, $subset->percentage_of_parent, $subset->discarded_read_count)
                        : (undef) x 3)
                ]);
            }
        }
    }
}

1;
