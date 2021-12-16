# Chris's Field Trip Examples

## Overview

This is a set of documentation and sample code intended to guide new users
through reading and processing our lab's data using Field Trip.

Some of this is done using Field Trip's code, and some of this is done
using my library code.

## Getting Started

Field Trip is a set of libraries that reads ephys data and performs signal
processing and various statistical analyses on it. It's a framework that
you can use to build your own analysis scripts.

To get Field Trip:
* Check that you have the Matlab toolboxes you'll need:
    * Signal Processing Toolbox (mandatory)
    * Statistics Toolbox (mandatory)
    * Optimization Toolbox (optional; needed for fitting dipoles)
    * Image Processing Toolbox (optional; needed for MRI)
* Go to [fieldtriptoolbox.org](https://www.fieldtriptoolbox.org).
* Click "latest release" in the sidebar on the top right
(or click [here](https://www.fieldtriptoolbox.org/#latest-release)).
* Look for "FieldTrip version (link) has been released". Follow that
GitHub link (example: 
[Nov. 2021 link](http://github.com/fieldtrip/fieldtrip/releases/tag/20211118)).
* Unpack the archive somewhere appropriate, and add that directory to
Matlab's search path.

Bookmark the following reference pages:
* [Tutorial list.](https://www.fieldtriptoolbox.org/tutorial)
* [Function reference.](https://www.fieldtriptoolbox.org/reference)

More documentation can be found at the
[documentation link](https://www.fieldtriptoolbox.org/documentation).

## Using Field Trip

A Field Trip script needs to do the following:
* Read the data.
* Perform re-referencing and artifact rejection.
* Filter the wideband data to get clean LFP-band and spike-band signals.
* Extract spike events and waveforms from the spike-band signal.
* Assemble event code information, reward triggers, and stimulation triggers
from TTL data.
* Time-align signals from different machines (recorder and stimulator) to
produce a unified dataset.
* Segment the data into epochs using event code information.
* Perform experiment-specific analysis.

Field Trip uses the following functions to do this; often several steps are
packaged together:
* `ft_read_header` reads a dataset's configuration information. You can
pass it a custom reading function to read data types it doesn't know about.
For Intan or Open Ephys data that will be a LoopUtil function.
* `ft_read_data` reads a dataset's raw ephys waveforms. You can pass it a
custom reading function to read data types it doesn't know about.
For Intan or Open Ephys data that will be a LoopUtil function.
* `ft_preprocessing` calls `ft_read_header` and `ft_read_data` to read a
dataset (all channels or a subset), and then performs re-referencing and
filtering on the resulting signals and optionally performs additional signal
processing (detrending, zero-averaging, rectification, computing the
derivative, computing the Hilbert transform). `ft_preprocessing` may also be
called on data that's already been read (this is how we'll be using it).
* `ft_resample` **FIXME** Details go here.
* `ft_definetrial` **FIXME** Details go here.
* **FIXME** Describe the "newconfig = function(oldconfig)" convention.

*This is the end of the file.*
