use 5.014;
use strict;
use warnings;

package App::Dwindling {
    use Getopt::Long qw< GetOptionsFromArray >;
    use FastQPE;
    use BAM;
    use base 'Exporter::Tiny';
    our @EXPORT = qw( parse_args stages_from stages_to_text stages_to_csv );

    sub parse_args {
        my @args = @_;

        # Parse --stage options into ([name, fwd, rev], [name, ...])
        my @stages;
        GetOptionsFromArray(
            \@args,
            'stage=s{2,4}' => sub {
                state $group = 0;
                push @{ $stages[$group] ||= [] }, $_[1];
                $group++ if $args[0] and $args[0] =~ /^-/;
            },
        ) or die "Invalid arguments";
        return @stages;
    }

    sub stages_from {
        my @stages;
        for my $stage (@_) {
            my ($name, @files) = @$stage;
            my %parent = $stages[-1]
                ? (parent => $stages[-1])
                : ();

            # FastQ: fwd, rev[, orphans]
            if (@files == 2 or @files == 3) {
                my ($fwd, $rev, $orphans) = @files;
                push @stages, FastQPE->new(
                    name    => $name,
                    fwd     => $fwd,
                    rev     => $rev,
                    (defined $orphans
                        ? (orphans => $orphans)
                        : ()),
                    %parent,
                );
            # BAM: bam
            } elsif (@files == 1 and $files[0] =~ /\.bam$/i) {
                push @stages, BAM->new(
                    name => $name,
                    file => $files[0],
                    %parent,
                );
            } else {
                die "Unrecognized file set (not PE FastQ or single BAM): ",
                    join(" ", @files), "\n";
            }
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
            if ($stage->DOES("Orphans") and $stage->orphans) {
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
                    (($stage->DOES("Orphans") and $stage->orphans)
                        ? ", including orphans"
                        : ""),
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

        $csv->print($out, [qw(stage_num stage type count parent_stage percentage_of_parent discarded_from_parent mapped_count)]);

        my $stage_num = 0;
        for my $stage (@_) {
            $stage_num++;
            for my $type ("total", "fwd", "rev", "orphans") {
                next if $type eq "orphans"
                    and not $stage->DOES("Orphans");

                my $subset = $type eq "total" ? $stage : $stage->$type
                    or next;
                $csv->print($out, [
                    $stage_num,
                    $stage->name,
                    $type,
                    $subset->read_count,
                    ($subset->parent
                        ? ($subset->parent->name, $subset->percentage_of_parent, $subset->discarded_read_count)
                        : (undef) x 3),
                    ($subset->DOES("MappedCount")
                        ? $subset->mapped_count
                        : undef),
                ]);
            }
        }
    }
}

1;
