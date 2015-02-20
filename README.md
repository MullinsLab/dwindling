# Dwindling Reads

## Usage:

    dwindling-reads [--csv] ::: <stage1> <files> [::: <stage2> <files> [::: <stage3> <files>]
    dwindling-reads --help

This program collates summary information from a set of next-gen sequencing
paired-end reads at each stage of your pipeline.

Each stage is separated by three colons (:::), followed by two to four
arguments.  The first argument is an arbitrary name of your choosing to
identify that stage.  Both FastQ (uncompressed and gzipped) and BAM files are
supported.  FastQ stages must specify at least two files for forward and
reverse reads.  An optional third file may be specified for single-end orphans,
such as those commonly produced by quality trimmers.  BAM stages must specify
only a single .bam file.

The standard Unix utilities zcat and wc must be installed, as well as samtools.

## Options:

    --csv     output CSV instead of formatted text
    --help    print usage message and exit

## Examples:

    dwindling-reads ::: raw     raw/ABC_R1.fq.gz raw/ABC_R2.fq.gz \
                    ::: sickle  trimmed/ABC_R1.fq trimmed/ABC_R2.fq trimmed/ABC_orphans.fq \
                    ::: mapped  ABC.bam

## Example output:

    196300 raw = 98150 forward + 98150 reverse

    161640 sickle = 80820 forward + 80820 reverse (= 82.34% of raw)
      6278 single-end orphans (= 3.20% of raw)
     34660 discarded, including orphans (= 17.66% of raw)

    161910 mapped = 80820 forward + 80820 reverse (= 100.17% of sickle)
      -270 discarded (= -0.17% of sickle)

    (In this case, bwa mem found 270 reads with secondary mappings so the reads
     are growing not dwindling!)

