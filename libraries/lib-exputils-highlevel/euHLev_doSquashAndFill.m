function newftdata = euHLev_doSquashAndFill( oldftdata, squashconfig )

% function newftdata = euHLev_doSquashAndFill( oldftdata, squashconfig )
%
% This function squashes specified time ranges, squashes excursions beyond
% a certain threshold from the median, adds a ramp to compensate for stepwise
% discontinuities across NaN ranges, and interpolates NaN ranges.
%
% These functions can be enabled, disabled, and tuned via a config structure.
%
% "oldftdata" is a ft_datatype_raw structure to modify.
% "squashconfig" is a configuration structure, per SQUASHCONFIG.txt.
%
% "newftdata" is a copy of "oldftdata" with the desired modifications made.


newftdata = oldftdata;


% Sanity check.
if isempty(squashconfig)
  squashconfig = struct();
end


% Get arguments.

squash_window_ms = [];
if isfield(squashconfig, 'squash_window_ms')
  squash_window_ms = squashconfig.squash_window_ms;
end

ramp_span_ms = [];
if isfield(squashconfig, 'ramp_span_ms')
  ramp_span_ms = squashconfig.ramp_span_ms;
end

auto_squash_threshold = NaN;
if isfield(squashconfig, 'auto_squash_threshold')
  auto_squash_threshold = squashconfig.auto_squash_threshold;
end

want_interp = false;
if isfield(squashconfig, 'want_interp')
  want_interp = squashconfig.want_interp;
end



% Squash manually specified time ranges.

if ~isempty(squash_window_ms)
  % Specify [] to put windows around t=0.
  windowmasks = ...
    nlFT_getWindowsAroundEvents( newftdata, squash_window_ms, [] );
  newftdata = nlFT_applyTimeWindowSquash( newftdata, windowmasks );
end



% Squash anything too far from the median, using a single span.
% FIXME - Maybe make a helper for this?

if isfinite(auto_squash_threshold)
  trialcount = length(newftdata.time);
  chancount = length(newftdata.label);

  for tidx = 1:trialcount
    thistime = newftdata.time{tidx};
    thistrial = newftdata.trial{tidx};

    for cidx = 1:chancount
      thiswave = thistrial(cidx,:);

      [ squashfirst squashlast threshlow threshhigh threshmedian ] = ...
        nlProc_getOutlierTimeRange( thistime, thiswave, [], [], 25, 75, ...
          auto_squash_threshold, auto_squash_threshold );
      thismask = (thistime >= squashfirst) & (thistime <= squashlast);
      thiswave(thismask) = NaN;

      thistrial(cidx,:) = thiswave;
    end

    newftdata.trial{tidx} = thistrial;
  end
end



% Apply a step correction ramp.

if ~isempty(ramp_span_ms)
  % Specify [] to measure a step across the NaN span (single span assumed).
  % This wants a ramp span in seconds, not milliseconds.
  newftdata = nlFT_rampOverStimStep( newftdata, ramp_span_ms / 1000, [] );
end



% Interpolate NaN segments.

if want_interp
  newftdata = nlFT_fillNaN(newftdata);
end



% Done.
end


%
% This is the end of the file.
