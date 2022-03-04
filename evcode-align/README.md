# Event Code Alignment Test Script

## Remarks

This is a script that was used to test low-level event code decoding and
time alignment functions during development.

Those functions have been packaged in `lib-exputils-align`, and this script
was rewritten to use high-level function calls and Field Trip where
feasible.

While this script could be used as sample code, and is still used for
regression testing, you're better off looking at the `ft_test` folder
for a more comprehensive example script.


## Documentation

The `manual` directory is the LaTeX build directory for documentation for
this script. Use `make -C manual` to rebuild it.

Right now this is mostly just an automated compilation of the source code.


## Notes

Notes about the sources of misalignment:

* Time misalignment is dominated by linear drift (a ramp) caused by clock
crystal frequency differences.
    * Crystal frequency mismatch is generally 0.1% to 0.2%; much wider than
the nominal precision of the crystals.
* With the ramp subtracted, you'll see the time delta drift on a timescale
of tens of minutes due to temperature changes next to the crystals.
    * Most devices use crystals with stability rated to 100 ppm. The Intan
machines use crystals with stability rated to 10 ppm. Temperature drift will
stay within this range.
* On short timescales, you'll see jitter (fuzz).
    * Plotting a histogram of jitter for computer sources typically gives you
a multi-peak distribution with peaks that are 0.1-0.2 ms wide and separated
by 1-2 ms. These are the precision of the OS's scheduler and the polling
interval for the OS's I/O drivers, respectively.
    * Plotting the histogram for the SynchBox gives a single-mode
distribution with a width of 0.1 ms (the SynchBox's scheduling interval).
    * Plotting it for the Intan machines gives a single-mode distribution
with a width of 0.03 or 0.05 ms (the sampling interval).

Notes about how the scripts perform time alignment:

* The goal is to align timestamps from different devices to within one sample
(0.03 ms).
* This is done by subtracting a global time offset, then getting successively
better estimates of the time difference between known reference points
(events that we have timestamps for from multiple devices).
* If you try to do this the easy way (linear interpolation between known
points), you'll be limited by jitter (fuzz) to plus or minus several samples.
* The point of the fine-tuning functions is to perform a fit in a
neighbourhood that contains several points, to average out this fuzz.
* There are other ways to do time alignment. This is just the one that I
used for my own implementation.


*(This is the end of the file.)*
