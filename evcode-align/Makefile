# Quick and dirty test script for event code time alignment - Makefile
# Written by Christopher Thomas.

MATLAB=matlab
MATFLAGS=-nodisplay -nodesktop -nosplash

default: clean run gallery

clean:
	rm -f plots/*

run:
	nice -n +10 $(MATLAB) $(MATFLAGS) -r "run('do_test.m'); exit;"

gallery:
	cd plots; makegallery.pl --width=24% *png; cd ..

package: clean
	tar -cvf ~/evcode-dev-tree.tar --exclude=milestones *

# This is the end of the file.
