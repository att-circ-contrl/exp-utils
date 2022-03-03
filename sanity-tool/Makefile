# Chris's Experiment Scripts - Data Sanity-Checker - Makefile
# Written by Christopher Thomas.

MATLAB=matlab
MATFLAGS=-nodisplay -nodesktop -nosplash
MATGUIFLAGS=-nodesktop -nosplash

default: clean run

clean:
	rm -f output/*

run:
	nice -n +10 $(MATLAB) $(MATFLAGS) \
		-r "run('do_sanity.m'); exit;"

rungui:
	nice -n +10 $(MATLAB) $(MATGUIFLAGS) \
		-r "run('do_sanity_gui.m'); exit;"


#
# This is the end of the file.
