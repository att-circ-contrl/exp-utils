# Event code alignment test script - Documentation - Makefile
# Written by Christopher Thomas.

REFNAME=evcodes-test-script
REFBASE=euscript-evcodes


REFBITS=\
	$(REFNAME).tex

REFAUTO=\
	$(REFBASE)-readme.tex		\
	$(REFBASE)-dostuff.tex		\
	$(REFBASE)-helpers.tex


default: force

ref: $(REFNAME).pdf

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
		"--chapter=Overview" --label=sect-readme \
		../README.md
	./copy-code.pl --outfile=$(REFBASE)-dostuff.tex --verbatim \
		"--chapter=Top-Level Scripts" --label=sect-dostuff \
		../do_*m
	./copy-code.pl --outfile=$(REFBASE)-helpers.tex --verbatim \
		"--chapter=Helper Functions" --label=sect-helpers \
		../do[A-Z]*m

$(REFNAME).pdf: $(REFBITS) refauto-bits
	pdflatex $(REFNAME).tex
	pdflatex $(REFNAME).tex
	make tclean

#
# This is the end of the file.
