# Chris's Field Trip Examples

## Overview

This is a set of documentation and sample code intended to guide new users
through reading and processing our lab's data using Field Trip.

This is done using Field Trip's functions where possible, augmented with my
library code for experiment-specific tasks.

## Getting Field Trip

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

## Other Libraries Needed

You're also going to need the following libraries. Download the relevant
GitHub projects and make sure the appropriate folders from them are on path:

* [Open Ephys analysis tools](https://github.com/open-ephys/analysis-tools)
(Needed for reading Open Ephys files; the root folder needs to be on path.)
* [NumPy Matlab](https://github.com/kwikteam/npy-matlab)
(Needed for reading Open Ephys files; the "npy-matlab" subfolder needs to be
on path.)
* My [LoopUtil libraries](https://github.com/att-circ-contrl/LoopUtil)
(Needed for reading Intan files and for integrating with Field Trip; the
"libraries" subfolder needs to be on path.)
* My [experiment utility libraries](https://github.com/att-circ-contrl/exp-utils-cjt)
(Needed for processing steps that are specific to our lab, and more Field
Trip integration; the "libraries" subfolder needs to be on path.)

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

### Reading Data with Field Trip

* `ft_read_header` reads a dataset's configuration information. You can
pass it a custom reading function to read data types it doesn't know about.
For Intan or Open Ephys data that will be a LoopUtil function.
* `ft_read_data` reads a dataset's raw ephys waveforms. You can pass it a
custom reading function to read data types it doesn't know about.
For Intan or Open Ephys data that will be a LoopUtil function. **NOTE:**
We don't normally call this; `ft_preprocessing` calls it instead.
* `ft_read_event` reads a dataset's event lists (TTL data is often stored as
events). You can pass it a custom reading function to read data types it
doesn't know about it.
* `ft_preprocessing` is a special case. It can either read data without
processing it, process data that's already read, or read data and then
process it. For reading data, it calls `ft_read_header` and `ft_read_data`
to read a dataset (all channels or a specified subset). You can pass it
custom reading functions for reading header information and data; for Intan
or Open Ephys data these will be LoopUtil functions.
* `ft_definetrial` **FIXME** Details go here.

### Signal Processing with Field Trip

* **FIXME** Describe the "newconfig = function(oldconfig)" convention.
* `ft_preprocessing` may be called to perform additional processing on data
that's already been read. It's typically used to perform re-referencing,
filtering, detrending, zero-averaging, rectification, computing of a signal's
derivative, and computing of a signal's Hilbert transform.
**FIXME** Describe `ft_preprocessing` call syntax here.
* `ft_resample` **FIXME** Details go here.

## Using LoopUtil and ExpUtils

**FIXME** Notes go here. Talk about event codes and time alignment. Mention
LoopUtils hooks for devices and its FT wrapper.

## A Typical Pre-Processing Script

The normal sequence of events is:

* Read header information using `ft_read_header`. This gives you a list of
channels present and metadata like the number of samples and the sampling
rate.
* Read TTL and event code data using `ft_read_event`.
* If you want monolithic data, read analog data using `ft_preprocessing`.
* Define trial time windows using `ft_definetrial`. (**FIXME** Or custom
code?)
* Read trial data using `ft_preprocessing`.
* Call `ft_preprocessing` to generate several different derived data series.
These typically include:
    * A low-pass-filtered and downsampled "LFP" series.
    * A high-pass-filtered "Spike" series.
    * A "rectified spiking activity" series. This is derived from the "Spike"
series by rectification (absolute value) followed by low-pass filtering and
downsampling.
* Save processed trial data to disk for further analysis.

A few useful notes:
* You'll generally save the processed trial data to disk, exit Matlab (or run
"`close all; clear all`"), and then run analysis scripts on the trial data.
The purpose of this is to reduce Matlab's memory footprint (which otherwise
can grow very quickly).
* If you're reading from multiple devices, you'll want to use
`ft_appenddata` to merge channels from the respective datasets. **NOTE:**
The datasets will need to have the same sampling rate before you can do this.
It's normally done with trial data that you've already pre-processed and
downsampled.
* For large datasets, the raw wideband data won't fit in memory. You'll have
to process it a few channels at a time or a few time windows at a time and
aggregate the results.


*This is the end of the file.*
