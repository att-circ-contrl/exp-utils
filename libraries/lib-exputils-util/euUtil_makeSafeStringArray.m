function [ newlabels newtitles ] = euUtil_makeSafeStringArray( oldstrings )

% function [ newlabels newtitles ] = euUtil_makeSafeStringArray( oldstrings )
%
% This function calls "euUtil_makeSafeString" on all elements of a
% one-dimensional cell array, making "safe" variants of all elements.
% The "label-safe" versions strip anything that's not alphanumeric.
% The "title-safe" versions replace stripped characters with spaces.
%
% This is more aggressive than filename- or fieldname-safe strings; in
% particular, underscores are interpreted as typesetting metacharacters in
% plot labels and titles.
%
% "oldstrings" is a 1D cell array containing character vectors to convert.
%
% "newlabels" is a cell array containing character vectors with only
%   alphanumeric characters.
% "newtitles" is a cell array containing character vectors with
%   non-alphanumeric characters replaced with spaces.


newlabels = {};
newtitles = {};

for lidx = 1:length(oldstrings)
  [thislabel thistitle] = euUtil_makeSafeString( oldstrings{lidx} );
  newlabels{lidx} = thislabel;
  newtitles{lidx} = thistitle;
end


% Done.
end


%
% This is the end of the file.
