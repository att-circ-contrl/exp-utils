# Chris's experiment utility libraries - Documentation - Makefile
# Written by Christopher Thomas.

REFNAME=exp-utils-cjt-libraries
REFBASE=eucjt-libs


REFBITS=\
	$(REFNAME).tex			\
	$(REFBASE)-over.tex

REFAUTO=\
	$(REFBASE)-sample-demo.tex	\
	$(REFBASE)-sample-synchbox.tex	\
	$(REFBASE)-align.tex		\
	$(REFBASE)-chris-notes.tex	\
	$(REFBASE)-chris.tex		\
	$(REFBASE)-ft-notes.tex		\
	$(REFBASE)-ft.tex		\
	$(REFBASE)-highlevel-notes.tex	\
	$(REFBASE)-highlevel.tex	\
	$(REFBASE)-meta-notes.tex	\
	$(REFBASE)-meta.tex		\
	$(REFBASE)-plot.tex		\
	$(REFBASE)-tools.tex		\
	$(REFBASE)-use-notes.tex	\
	$(REFBASE)-use.tex		\
	$(REFBASE)-util-notes.tex	\
	$(REFBASE)-util.tex


default: force

libref: $(REFNAME).pdf
	cp $(REFNAME).pdf ../manuals

force: clean libref
	make autoclean

clean: tclean autoclean
	rm -f $(CHANGUIDE).pdf
	rm -f $(REFNAME).pdf

autoclean:
	rm -f $(REFAUTO)

tclean:
	rm -f $(REFNAME)*.log $(REFNAME)*.aux $(REFNAME)*.toc
	rm -f texput.*


refauto-bits: refauto-code refauto-notes refauto-examples

refauto-code:
	./copy-code.pl --outfile=$(REFBASE)-align.tex --matlabdoc \
		"--chapter=\`\`euAlign'' Functions" --label=sect-align \
		../libraries/lib-exputils-align/*m
	./copy-code.pl --outfile=$(REFBASE)-chris.tex --matlabdoc \
		"--chapter=\`\`euChris'' Functions" --label=sect-chris \
		../libraries/lib-exputils-chris/*m
	./copy-code.pl --outfile=$(REFBASE)-ft.tex --matlabdoc \
		"--chapter=\`\`euFT'' Functions" --label=sect-ft \
		../libraries/lib-exputils-ft/*m
	./copy-code.pl --outfile=$(REFBASE)-highlevel.tex --matlabdoc \
		"--chapter=\`\`euHLev'' Functions" --label=sect-highlevel \
		../libraries/lib-exputils-highlevel/*m
	./copy-code.pl --outfile=$(REFBASE)-meta.tex --matlabdoc \
		"--chapter=\`\`euMeta'' Functions" --label=sect-meta \
		../libraries/lib-exputils-meta/*m
	./copy-code.pl --outfile=$(REFBASE)-plot.tex --matlabdoc \
		"--chapter=\`\`euPlot'' Functions" --label=sect-plot \
		../libraries/lib-exputils-plot/*m
	./copy-code.pl --outfile=$(REFBASE)-tools.tex --matlabdoc \
		"--chapter=\`\`euTools'' Functions" --label=sect-tools \
		../libraries/lib-exputils-tools/*m
	./copy-code.pl --outfile=$(REFBASE)-use.tex --matlabdoc \
		"--chapter=\`\`euUSE'' Functions" --label=sect-use \
		../libraries/lib-exputils-use/*m
	./copy-code.pl --outfile=$(REFBASE)-util.tex --matlabdoc \
		"--chapter=\`\`euUtil'' Functions" --label=sect-util \
		../libraries/lib-exputils-util/*m

refauto-notes:
	./copy-code.pl --outfile=$(REFBASE)-chris-notes.tex --verbatim \
		"--chapter=\`\`euChris'' Notes" --label=sect-chris-notes \
		../libraries/lib-exputils-chris/*txt
	./copy-code.pl --outfile=$(REFBASE)-ft-notes.tex --verbatim \
		"--chapter=\`\`euFT'' Notes" --label=sect-ft-notes \
		../libraries/lib-exputils-ft/*txt
	./copy-code.pl --outfile=$(REFBASE)-highlevel-notes.tex --verbatim \
		"--chapter=\`\`euHLev'' Notes" --label=sect-highlevel-notes \
		../libraries/lib-exputils-highlevel/*txt
	./copy-code.pl --outfile=$(REFBASE)-meta-notes.tex --verbatim \
		"--chapter=\`\`euMeta'' Notes" --label=sect-meta-notes \
		../libraries/lib-exputils-meta/*txt
	./copy-code.pl --outfile=$(REFBASE)-use-notes.tex --verbatim \
		"--chapter=\`\`euUSE'' Notes" --label=sect-use-notes \
		../libraries/lib-exputils-use/*txt
	./copy-code.pl --outfile=$(REFBASE)-util-notes.tex --verbatim \
		"--chapter=\`\`euUtil'' Notes" --label=sect-util-notes \
		../libraries/lib-exputils-util/*txt

refauto-examples:
	./copy-code.pl --outfile=$(REFBASE)-sample-synchbox.tex --verbatim \
		"--chapter=\`\`synchbox-demo'' Example Script" \
		--label=sect-sample-synchbox \
		../synchbox-demo/README.md ../synchbox-demo/*m
	./copy-code.pl --outfile=$(REFBASE)-sample-demo.tex --verbatim \
		"--chapter=\`\`ft-demo'' Example Script" \
		--label=sect-sample-demo \
		../ft-demo/README.md ../ft-demo/*m

$(REFNAME).pdf: $(REFBITS) refauto-bits
	pdflatex $(REFNAME).tex
	pdflatex $(REFNAME).tex
	make tclean

#
# This is the end of the file.
