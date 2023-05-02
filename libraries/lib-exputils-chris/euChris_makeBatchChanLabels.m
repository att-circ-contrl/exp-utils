function chanlabels = euChris_makeBatchChanLabels( chanpattern, channums )

% function chanlabels = euChris_makeBatchChanLabels( chanpattern, channums )
%
% This produces a cell array containing channel labels, by iterating
% through a list of channel numbers and applying a sprintf pattern.
%
% "chanpattern" is a spritnf pattern for channel names that accepts a
%   channel number as an argument.
% "channums" is a vector containing channel numbers to format.
%
% "chanlabels" is a cell array containing formatted channel labels.


chanlabels = {};
for cidx = 1:length(channums)
  chanlabels{cidx} = sprintf( chanpattern, channums(cidx) );
end


% Done.
end


%
% This is the end of the file.
