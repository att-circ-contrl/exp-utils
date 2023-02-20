function [ aligned_time, aligned_first, aligned_second ] = ...
  euAlign_getResampledOverlappedWaves( ...
    first_time, first_wave, second_time, second_wave, time_bin_size )

% function [ aligned_time, aligned_first, aligned_second ] = ...
%   euAlign_getResampledOverlappedWaves( ...
%     first_time, first_wave, second_time, second_wave, time_bin_size )
%
% This processes two input waveforms that were sampled using different time
% series, and produces versions of these waveforms sampled using a common
% time series for the portions of the waveforms that overlap in time.
%
% This does quick and dirty resampling via time binning, averaging samples
% within each bin. There must be at least one time sample from each input
% waveform within each bin. Since the bin window has a top-hat profile, high
% frequencies may be aliased down during resampling.
%
% "first_time" is a vector with sampling times for the first waveform.
% "first_wave" is a vector with sample values for the first waveform.
% "second_time" is a vector with sampling times for the second waveform.
% "second_wave" is a vector with sample values for the second waveform.
% "time_bin_size" is the duration of the time bins to use when resampling.
%
% "aligned_time" is a vector containing the centre values of each time bin.
% "aligned_first" is a vector containing sample values from the first
%   waveform, averaged within each time bin.
% "aligned_second" is a vector containing sample values from the second
%   waveform, averaged within each time bin.


aligned_time = [];
aligned_first = [];
aligned_second = [];


% Force sanity.

thismask = isfinite(first_time);
first_time = first_time(thismask);
first_wave = first_wave(thismask);

thismask = isfinite(second_time);
second_time = second_time(thismask);
second_wave = second_wave(thismask);


if (~isempty(first_time)) && (~isempty(second_time))

  timestart = max( min(first_time), min(second_time) );
  timeend = min( max(first_time), max(second_time) );


  % Trim the lists to avoid processing non-common parts.

  thismask = (first_time >= timestart) & (first_time <= timeend);
  first_time = first_time(thismask);
  first_wave = first_wave(thismask);

  thismask = (second_time >= timestart) & (second_time <= timeend);
  second_time = second_time(thismask);
  second_wave = second_wave(thismask);

end

if (~isempty(first_time)) && (~isempty(second_time))

  [ aligned_time aligned_first ] = helper_doBinnedResample( ...
    first_time, first_wave, timestart, timeend, time_bin_size);

  [ aligned_time aligned_second ] = helper_doBinnedResample( ...
    second_time, second_wave, timestart, timeend, time_bin_size);

end


% Done.
end



%
% Helper functions.

function [ aligned_time aligned_data ] = helper_doBinnedResample( ...
    wave_time, wave_data, timestart, timeend, time_bin_size)

  aligned_time = [];
  aligned_data = [];

  % Do this the O(n log n) way, by sorting by time and walking through it.

  [ wave_time sortidx ] = sort(wave_time);
  wave_data = wave_data(sortidx);

  tidx = 1;
  binstart = timestart;

  sidx = 1;
  sidxmax = length(wave_time);

  % Shouldn't happen, but bulletproof it anyways.
  while (sidx <= sidxmax) && (wave_time(sidx) < binstart)
    sidx = sidx + 1;
  end

  while binstart < timeend
    % Start this bin.
    binend = binstart + time_bin_size;
    thisspan = [];

    % Add samples to this bin.
    while (sidx <= sidxmax) && (wave_time(sidx) <= binend)
      thisspan = [ thisspan wave_data(sidx) ];
      sidx = sidx + 1;
    end

    % Finish this bin.
    % The mean of an empty span is NaN, which is fine.
    aligned_time(tidx) = 0.5 * (binstart + binend);
    aligned_data(tidx) = mean(thisspan);

    % Move to the next bin.
    binstart = binend;
    tidx = tidx + 1;
  end

end


%
% This is the end of the file.
