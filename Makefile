.DELETE_ON_ERROR:

cpanm := inc/bin/cpanm

$(cpanm):
	mkdir -p inc/bin/
	curl -fsSL https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm > $@
	chmod +x $@

bundle: $(cpanm) cpanfile
	$(cpanm) -l inc --notest --mirror https://cpan.metacpan.org --mirror-only --verify --installdeps .

README.md: dwindling-reads Examples.md INSTALL.md
	(echo "# Dwindling Reads"; ./$< --help) \
		| perl -pe 's/^(?=[\w -]+:$$)/## /' \
		> $@
	for file in $(filter-out $<,$^); do \
		echo >> $@; \
		cat $$file >> $@; \
	done

%.png: %.svg
	cairosvg -f png -o $@ $<
