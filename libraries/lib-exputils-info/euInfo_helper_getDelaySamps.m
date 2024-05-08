function delaylist_samps = ...
  euInfo_helper_getDelaySamps( samprate, delay_range_ms, delay_step_ms )

% function delaylist_samps = ...
%   euInfo_helper_getDelaySamps( samprate, delay_range_ms, delay_step_ms )
%
% This converts a time lag range and stride (in milliseconds) into delay
% offsets (in samples).
%
% "samprate" is the sampling rate.
% "delay_range_ms" [ min max ] is the range of delays to generate, in
%   milliseconds. If this is a scalar, only that delay is generated.
% "delay_step_ms" is the number of milliseconds between generated delays.
%
% "delaylist_samps" is a vector with delay values in samples.


delaylist_samps = [];


%
% Convert range and stride to samples.

delaymin_samps = min( delay_range_ms );
delaymin_samps = round( samprate * delaymin_samps * 0.001 );

delaymax_samps = max( delay_range_ms );
delaymax_samps = round( samprate * delaymax_samps * 0.001 );

delaystep_samps = round( samprate * delay_step_ms * 0.001 );
delaystep_samps = max( 1, delaystep_samps );


%
% Pick a pivot point.

% We're doing this so that if 0 is in range, we can guarantee it's one of
% the delay values tested.

delaypivot = round( 0.5 * (delaymin_samps + delaymax_samps) );

% If a delay of zero is in range, make sure we use it as one of the delays.
if (delaymin_samps <= 0) & (delaymax_samps >= 0)
  delaypivot = 0;
end


%
% Generate delays around the pivot.

if length( delay_range_ms ) < 2

  % Delay range was a scalar. Just use that value.
  delaylist_samps = delaypivot;

else

  % Delay range was a range. Proceed as normal.

  % This correctly handles the case where range is smaller than stride
  % (generating a single delay).

  delaymin_samps = delaymin_samps - delaypivot;
  delaymin_samps = round(delaymin_samps / delaystep_samps);
  delaymin_samps = (delaymin_samps * delaystep_samps) + delaypivot;

  delaymax_samps = delaymax_samps - delaypivot;
  delaymax_samps = round(delaymax_samps / delaystep_samps);
  delaymax_samps = (delaymax_samps * delaystep_samps) + delaypivot;

  delaylist_samps = [ delaymin_samps : delaystep_samps : delaymax_samps ];

end


% Done.
end


%
% This is the end of the file.
