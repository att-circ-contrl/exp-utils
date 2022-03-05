# Field Trip sample script - Documentation - Makefile
# Written by Christopher Thomas.

REFNAME=ft-test-script
REFBASE=euscript-fttest


REFBITS=\
	$(REFBASE)-over.tex		\
	$(REFNAME).tex

REFAUTO=\
	$(REFBASE)-readme.tex		\
	$(REFBASE)-topmeta.tex		\
	$(REFBASE)-align.tex		\
	$(REFBASE)-trials.tex		\
	$(REFBASE)-helper.tex		\
	$(REFBASE)-plot.tex		\
	$(REFBASE)-check.tex		\
	$(REFBASE)-mono.tex


default: force

ref: $(REFNAME).pdf
	cp $(REFNAME).pdf ../../manuals

force: clean ref
	make autoclean

clean: tclean autoclean
	rm -f $(REFNAME).pdf

autoclean:
	rm -f $(REFAUTO)

tclean:
	rm -f $(REFNAME)*.log $(REFNAME)*.aux $(REFNAME)*.toc
	rm -f texput.*


refauto-bits:
	./copy-code.pl --outfile=$(REFBASE)-readme.tex --verbatim \
		"--chapter=ReadMe File" --label=sect-readme \
		../README.md
	./copy-code.pl --outfile=$(REFBASE)-topmeta.tex --verbatim \
		"--chapter=Top-Level and Metadata" --label=sect-topmeta \
		../do_test.m ../do_test_config.m ../do_test_datasets.m \
		../do_test_get_metadata.m
	./copy-code.pl --outfile=$(REFBASE)-align.tex --verbatim \
		"--chapter=Time Alignment" --label=sect-align \
		../do_test_align.m
	./copy-code.pl --outfile=$(REFBASE)-trials.tex --verbatim \
		"--chapter=Trial Processing" --label=sect-trials \
		../do_*trials.m
	./copy-code.pl --outfile=$(REFBASE)-helper.tex --verbatim \
		"--chapter=Helper Functions" --label=sect-helper \
		../do[CF]*m ../doPower*m ../doS*m
	./copy-code.pl --outfile=$(REFBASE)-plot.tex --verbatim \
		"--chapter=Plotting" --label=sect-plot \
		../doBrowse*m ../doPlot*m
	./copy-code.pl --outfile=$(REFBASE)-check.tex --verbatim \
		"--chapter=Signal Quality Checking" --label=sect-check \
		../do_*auto*m
	./copy-code.pl --outfile=$(REFBASE)-mono.tex --verbatim \
		"--chapter=Monolithic Processing" --label=sect-mono \
		../do_*monolithic.m

$(REFNAME).pdf: $(REFBITS) refauto-bits
	pdflatex $(REFNAME).tex
	pdflatex $(REFNAME).tex
	make tclean

#
# This is the end of the file.
