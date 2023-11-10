function titlelist = euChris_makePrettySessionTitles_loop3202( labellist )

% function titlelist = euChris_makePrettySessionTitles_loop3202( labellist )
%
% This attempts to parse a list of session labels, returning a list of
% pretty session titles. Labels that couldn't be parsed are used directly
% as titles.
%
% "labellist" is a cell array of character vectors with session labels.
%
% "titleelist" is a cell array of character vectors with human-readable
%   session titles.


titlelist = labellist;

for lidx = 1:length(labellist)
  [ thisdatenum thisdatetext thissuffix ] = ...
    euChris_parseSessionLabel_loop2302( labellist{lidx} );

  if ~isnan( thisdatenum )

    [ thisyear thismonthnum thismonthshort thismonthlong thisday ] = ...
      euUtil_parseDateNumber( thisdatenum );

    thistitle = sprintf('%02d %s', thisday, thismonthshort );

    if ~isnan(thisyear)
      thistitle = [ thistitle sprintf(' %d', thisyear) ];
    end

    if ~isempty( thissuffix )
      thistitle = [ thistitle ' ' thissuffix ];
    end

    titlelist{lidx} = thistitle;
  end
end


% Done.
end


%
% This is the end of the file.
