# Chris's Field Trip Example Script

## Overview

This is a minimum working script showing how to read data from one of our
lab's experiments into Field Trip and perform processing with it.

About half of this is done using Field Trip's functions directly, and the
remainder is done with wrapper functions that combine many common Field Trip
operations. If you're not sure what a step is doing or how it's doing it,
looking at that function's documentation and function body will help.

To run this script, you'll need Field Trip and several libraries installed;
details are below.

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
* Read the TTL data from ephys machines and SynchBox data from USE.
* Assemble event code information, reward triggers, and stimulation triggers
from TTL and SynchBox data.
* Time-align signals from different machines (recorder, stimulator, SynchBox,
and USE) to produce a unified dataset.
* Segment the data into trials using event code information.
* Read the analog data trial by trial (to keep memory footprint reasonable).
* Perform re-referencing and artifact rejection.
* Filter the wideband data to get clean LFP-band and high-pass signals.
* Extract spike events and waveforms from the high-pass signal.
* Extract average spike activity (multi-unit activity) from a band-pass signal.
* Stack trigger-aligned trials on to each other and get the average response
and variance of time-aligned trials (a "timelock analysis").
* Perform experiment-specific analysis.

### Reading Data with Field Trip

* `ft_read_header` reads a dataset's configuration information.
* `ft_read_event` reads a dataset's event lists (TTL data is often stored as
events).
* `ft_preprocessing` is a "do-everything" function. It can either read data
without processing it, process data that's already read, or read data and then
process it. At minimum you'll use it to read data.

For all of these, you can pass it a custom reading function to read data
types it doesn't know about it. We need to do this for all of our data (Intan,
Open Ephys, and USE). You can tell it to use appropriate NeuroLoop functions
to read these types of data, per the sample code. It can also be told to
read events from tables in memory using NeuroLoop functions.

**NOTE** - When reading data, you pass a trial definition table as part of
the configuration structure. Normally this is built using `ft_definetrial`,
but because of the way our event codes are set up and because we have to
do time alignment between multiple devices, we build this table manually.

We're using `euFT_defineTrialsUsingCodes()` for this.

### Signal Processing with Field Trip

* Field Trip signal processing calls take the form
"`newdata = ft_XXX(config, olddata)`. These can be made through calls
to `ft_preprocessing` or by calling the relevant `ft_XXX` functions
directly (these are in the `preproc` folder). The configuration structure
only has to contain the arguments that the particular operation you're
performing cares about.
* ONLY call functions that begin with `ft_`. In particular, anything in the
"`private`" directory should not be called (its implementation and
arguments will change as FT gets updated). The `ft_XXX` functions are
guaranteed to have a stable interface.
* *Almost* all signal processing operations can be performed through
`ft_preprocessing`. The exception is resampling: Call `ft_resampledata`
to do that.
* See the preamble of `ft_preprocessing` for a list of available signal
processing operations and the parameters that need to get set to perform
them.

### Field Trip Data Structures

Data structures I kept having to look up were the following:

* `ft_datatype_raw` is returned by `ft_preprocessing` and other signal
processing functions. Relevant fields are:
    * `label` is a {Nchans x 1} cell array of channel names.
    * `time` is a {1 x Ntrials} cell array of [1 x Nsamples] time axis
vectors. Taking the lengths of these will give you the number of samples in
each trial without having to load the trial data itself.
    * `trial` is a {1 x Ntrials} cell array of [Nchans x Nsamples] waveform
matrices. This is the raw waveform data.
    * `fsample` is "deprecated", but it's still the most reliable way to get
the sampling rate for a data structure. Reading it from the header (which
is also appended in the data) gives you the wrong answer if you've resampled
the data (and you often will downsample it).
    * Trial metadata is also included in `ft_datatype_raw`, but it's much
simpler to keep track of that separately if you're the one who defined the
trials in the first place.

* A **header** is returned by `ft_read_header`, and is also included in data as
the `ft_datatype_raw.hdr` field. Relevant fields are:
    * `Fs` is the *original* sampling rate, before any signal processing.
    * `nChans` is the number of channels.
    * `label` is a {Nchans x 1} cell array of channel names.
    * `chantype` is a {Nchans x 1} cell array of channel type labels. These
are arbitrary, but can be useful if you know the conventions used by the
hardware-specific driver function that produced them. See the LoopUtil
documentation for the types used by the LoopUtil library.
    * `nTrials` is the number of trials in the raw data. This should always
be 1 for continuous recordings like we're using.

* A **trial definition matrix** is a [Ntrials x 3] matrix defining a set of
trials.
    * This is passed as `config.trl` when calling `ft_preprocessing` to
read data from disk.
    * Columns are `first sample`, `last sample`, and `trigger offset`. The
trigger offset is `(first sample - trigger sample)`; a positive value means
the trial started after the trigger, and a negative value means the trial
started before the trigger.
    * Additional columns from custom trial definition functions get stored
in `config.trialinfo`, which is a [Ntrials x (extra columns)] matrix.
    * **NOTE** - According to the documentation, trial definitions (`trl`
and `trialinfo`) can be Matlab tables instead of matrices, which allows
column names and non-numeric data to be stored. I haven't tested this, and
I suspect that it may misbehave in some situations. Since we're defining the
trials ourselves instead of with `ft_definetrial`, I just store trial
metadata in a separate Matlab variable.

## What This Script Does

This script performs most of the steps we'll want to perform when
pre-processing data from real experiments:

* It finds the recorder, stimulator, and USE folders and reads metadata
from the recorder and stimulator.
* It reads digital/TTL events from the recorder, stimulator, and USE folders.
The USE data includes what USE sent to the SynchBox (only USE timestamps) and
what the SynchBox sent back (also has SynchBox timestamps).
* It reads gaze and frame data tables from USE.
* It aligns timestamps from all of these sources and translates everything
into the recorder's timeframe.
* It makes sure there's a consistent list with all of the events, since
the recorder and stimulator are sometimes not set up to save all TTL inputs.
* It processes the list of event codes to find out when trials should happen.
This is done using `euFT_defineTrialsUsingCodes()`, since we need metadata
that `ft_definetrial()` doesn't usually look at, and since we're using
`TrlStart` and `TrlEnd` to define the trial boundaries instead of fixed
padding times.
* It reads the ephys data for all trials, performing filtering:
    * Power line noise and other narrow-band noise is filtered out of the
wideband data.
    * The wideband data is low-pass filtered and downsampled to get LFP data.
    * The wideband data is high-pass filtered to get spike waveform data.
    * The wideband data is band-pass filtered, rectified, low-pass filtered,
and downsampled to get multi-unit activity data.
* It segments USE event and gaze data per trial as well.
* It computes timelock averages of LFP and MUA data.
* It generates example plots for all of these.

Things that are missing:

* We're not identifying trials with artifacts. This is typically done
manually, though automated tools are provided in the LoopUtil library.

* We're not re-referencing the data. Field Trip provides preprocessing
options for this, but we'll probably have to do it probe by probe rather
than across the whole dataset (common-average referencing the recording
channels for each probe).

## Miscellaneous Notes

* Right now, data from each device is aligned but stored separately.
Eventually we'll want to use `ft_appenddata` to merge data from multiple
devices (such as multiple Intan recording controllers, if we're using more
than 8 headstages). This can only be done for data that's at a single
sampling rate, which may not be practical for wideband and raw spike data.

* Right now, the script doesn't touch spike sorting or try to isolate
single-unit spiking activity. The spike sorting pipeline presently needs to
work on the entire monolithic dataset, rather than on trials, and that
monolithic dataset won't fit in memory. What we're going to have to do is
load monolithic data per-probe (64 or 128 channels) and re-save that for the
spike sorting pipeline to process (after notch filtering and artifact
removal).


*This is the end of the file.*
