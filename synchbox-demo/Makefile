# Quick and dirty test program for parsing USE synchbox traffic.

MATLAB=matlab
MATFLAGS=-nodisplay -nodesktop -nosplash

default: force

force: clean run

clean:
	rm -f output/*

checkdirs:
	./checkdirs.sh

run: checkdirs
	nice -n +10 $(MATLAB) $(MATFLAGS) \
		-r "dbstop if error; run('do_read_synchbox.m'); exit;"

# This is the end of the file.
