# Installation

This software requires the following 

* Perl 5.8.5 or newer (5.8.5 is absolutely ancient!)
* zcat (distributed with gzip)
* wc (distributed with coreutils)
* [samtools](http://htslib.org)

The first three are generally pre-installed on most Linux/Unix operating
systems.

In addition, several Perl libraries from [CPAN](http://cpan.org) are needed and
described in the `cpanfile`.  The quickest way to satisfy the Perl
prerequisites is by running:

    make bundle

from within a clone of the git repository.  This command will download
[cpanm](https://metacpan.org/pod/App::cpanminus) and use it to install the
required dependencies into the `inc/` directory.  The `dwindling-reads` program
will automatically use libraries in this directory if they exist.
