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
* Read the TTL data.
* Assemble event code information, reward triggers, and stimulation triggers
from TTL data.
* Time-align signals from different machines (recorder and stimulator) to
produce a unified dataset.
* Segment the data into trials using event code information.
* Read the analog data trial by trial (to keep memory footprint reasonable).
* Perform re-referencing and artifact rejection.
* Filter the wideband data to get clean LFP-band and high-pass signals.
* Extract spike events and waveforms from the high-pass signal.
* Extract average spike activity from the high-pass signal.
* Perform experiment-specific analysis.

### Reading Data with Field Trip

* `ft_read_header` reads a dataset's configuration information. You can
pass it a custom reading function to read data types it doesn't know about.
For Intan or Open Ephys data that will be a LoopUtil function.
* `ft_read_event` reads a dataset's event lists (TTL data is often stored as
events). You can pass it a custom reading function to read data types it
doesn't know about it.
* `ft_preprocessing` is a "do-everything" function. It can either read data
without processing it, process data that's already read, or read data and then
process it. At minimum you'll use it to read data.

**NOTE** - When reading data, you pass a trial definition table as part of
the configuration structure. Normally this is built using `ft_definetrial`,
but because of the way our event codes are set up and because we have to
do time alignment between multiple devices, we build this table manually.

This is done in `do_test_define_trials.m`. At some point this will get
cleaned up and folded into library functions (along with much of the rest
of this script).

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

## Minimum Working Example

For a very minimal example of Field Trip code, examine the
`euTools_sanityCheckTree` function in `lib-exputils-tools`.

* This does not do time alignment.
* This does not read USE data.
* This does not read TTL data (or any other events).
* This does not integrate data from multiple pieces of equipment.

What it *does* do is read individual saved datasets and perform signal
processing on small segments of them, using Field Trip's hooks.

## A More Complex Example

The scripts in this directory perform all of the steps we'll want to perform
when pre-processing data from real experiments:

* Metadata for the recorder and stimulator datasets are read using
`ft_read_header`.
* Recorder and stimulator TTL data is read using `ft_read_event`. This is
assembled into event codes and reward/timer events.
* USE event data is read using `lib-exputils-use` functions. This includes
a record of SynchBox and eye-tracker activity.
* USE, SynchBox, eye-tracker, and TTL data are time-aligned (using event
codes if possible, other signals if not). Time alignment tables are built
that can translate any piece of equipment's timestamps into recorder time.
* Trials are defined based on appropraite event codes.
* `ft_preprocessing` is called to read the resulting trial ephys data. This
happens in small batches of trials to avoid filling memory.
* Signal processing is performed on the trials:
    * Common-average referencing is performed on various pools of signals,
if pools for this are defined.
    * Notch filtering is applied to remove power line noise and its harmonics,
as well as any beat frequencies introduced by equipment sampling rates.
    * A "local field potential" signal is generated by low-pass-filtering and
downsampling.
    * A "raw spikes" signal is generated by high-pass-filtering at the native
sampling rate.
    * A "rectified spiking activity" series ("multi-unit activity" series)
is generated by rectifying the "raw spikes" series (taking the absolute
value), followed by low-pass filtering and downsampling.
* Eye-tracker data, TTL data, and event data that overlaps each trial is
extracted.
* Processed analog and digital signals and events from batches of trials
are saved to disk, along with trial metadata.

The intention is that after this preprocessing is done, the experiment
analysis can be performed without having to touch the raw data again.

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
