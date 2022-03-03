% Quick and dirty test script for dataset sanity-checking.
% Written by Christopher Thomas.

do_paths;
do_quiet;

if ~exist('sourcedir', 'var')
  % NOTE - Pick the subfolder for a rapid test.
  %sourcedir = 'datasets';
  sourcedir = 'datasets/*tungsten';
end

% Set up configuration to look at the early part of the data.
% This avoids stimulation artifacts.
config = struct( 'readposition', 0.05 );

[ reporttext folderdata ] = euTools_sanityCheckTree( sourcedir, config );

save( 'output/sanitydata.mat', 'reporttext', 'folderdata', '-v7.3' );

thisfid = fopen('output/sanityreport.txt', 'w');
fwrite(thisfid, reporttext);
fclose(thisfid);

%
% This is the end of the file.
