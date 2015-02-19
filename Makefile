.DELETE_ON_ERROR:

cpanm := inc/bin/cpanm

$(cpanm):
	mkdir -p inc/bin/
	curl -fsSL https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm > $@
	chmod +x $@

bundle: $(cpanm) cpanfile
	$(cpanm) -L inc --notest --mirror https://cpan.metacpan.org --mirror-only --verify --installdeps .
