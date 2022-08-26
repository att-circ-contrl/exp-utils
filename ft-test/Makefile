# Chris's Experiment Scripts - Field Trip - Makefile
# Written by Christopher Thomas.

MATLAB=matlab
MATFLAGS=-nodisplay -nodesktop -nosplash
MATGUIFLAGS=-nodesktop -nosplash

default: clean run gallery

force: allclean run gallery

debug: clean rundebug gallery

clean:
	rm -f plots/*

allclean: clean
	rm -f output/*

run:
	./checkdirs.sh
	nice -n +10 $(MATLAB) $(MATFLAGS) \
		-r "run('do_test.m'); exit;"

rungui:
	./checkdirs.sh
	nice -n +10 $(MATLAB) $(MATGUIFLAGS) \
		-r "run('do_test.m'); exit;"

rundebug:
	./checkdirs.sh
	nice -n +10 $(MATLAB) $(MATFLAGS) \
		-r "dbstop if error; run('do_test.m'); exit;"

docs:
	make -C manual

dclean:
	make -C manual clean

gallery:
	cd plots; makegallery.pl --width=24% --nofolders *png; cd ..

gallery3:
	cd plots; makegallery.pl --width=32% --nofolders *png; cd ..

#
# This is the end of the file.
