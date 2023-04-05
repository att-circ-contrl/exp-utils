% Quick and dirty test script for dataset sanity-checking.
% Written by Christopher Thomas.

do_paths;
do_quiet;

if ~exist('sourcedir', 'var')
  % NOTE - Pick the tungsten folders for a rapid test.
%  sourcedir = 'datasets';
%  sourcedir = 'datasets-samples/*tungsten';
%  sourcedir = 'datasets-samples/20220504*';
  sourcedir = 'datasets-teba/igor-vu595-recording-duplicates/';
end

config = struct();

% Set up configuration to look at the early part of the data.
% This avoids stimulation artifacts.
%config.readposition = 0.05;

% Hand-tuned thresholds for 2023 Igor data.
config.correlthreshabslfp = 0.999;
config.correlthreshabsspike = 0.99;

[ reportshort reportlong folderdata ] = ...
  euTools_sanityCheckTree( sourcedir, config );

save( 'output/sanitydata.mat', ...
  'reportshort', 'reportlong', 'folderdata', '-v7.3' );

nlIO_writeTextFile('output/sanitysummary.txt', reportshort);
nlIO_writeTextFile('output/sanityreport.txt', reportlong);

%
% This is the end of the file.
