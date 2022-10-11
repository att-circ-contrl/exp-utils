% Quick and dirty test script for dataset sanity-checking.
% Written by Christopher Thomas.

do_paths;
do_quiet;

if ~exist('sourcedir', 'var')
  % NOTE - Pick the tungsten folders for a rapid test.
%  sourcedir = 'datasets';
%  sourcedir = 'datasets-samples/*tungsten';
  sourcedir = 'datasets-samples/20220504*';
end

% Set up configuration to look at the early part of the data.
% This avoids stimulation artifacts.
config = struct( 'readposition', 0.05 );

[ reportshort reportlong folderdata ] = ...
  euTools_sanityCheckTree( sourcedir, config );

save( 'output/sanitydata.mat', ...
  'reportshort', 'reportlong', 'folderdata', '-v7.3' );

thisfid = fopen('output/sanitysummary.txt', 'w');
fwrite(thisfid, reportshort, 'char*1');
fclose(thisfid);

thisfid = fopen('output/sanityreport.txt', 'w');
fwrite(thisfid, reportlong, 'char*1');
fclose(thisfid);

%
% This is the end of the file.
