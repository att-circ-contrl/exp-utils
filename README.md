# Chris's Experiment Utilities

## Overview

This is a set of libraries and utilities written to support ephys experiment
analyses in Thilo's lab.

This is intended to be a private project for lab-specific code that is not
specific to individual experiments. Code that lends itself to reuse outside
of our lab can be migrated to public projects. Code that's
experiment-specific should be in projects associated with those experiments.


## Libraries

Libraries are provided in the `libraries` directory. With that directory
on path, call the `addPathsExpUtilsCjt` function to add sub-folders.

The following subdirectories contain library code:

* `lib-exputils-align` --
Time-alignment of event lists from different sources.
* `lib-exputils-ft` --
Field Trip utility functions that aren't general enough to migrate to
LoopUtil.
* `lib-exputils-use` --
Functions for reading and interpreting USE data (event codes, SynchBox
activity, gaze data).


## Sample Code

Sample code project folders are as follows:

* `evcode-align` --
Sample code for reading event codes from a dataset, performing time alignment
between the ephys recorder, the USE computer, and the SynchBox, and
reporting time alignment precision statistics.
* `ft-test` --
Test scripts, sample code, and documentation for using Field Trip with our
lab's datasets (including time alignment and USE integration).


*This is the end of the file.*
