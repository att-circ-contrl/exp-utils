function newfeatures = euChris_calcNormalizedFeatureResponse( ...
  oldfeatures, oldfield, normfield, baselinefield, ...
  case_compare_lut, casefield, matchfields )

% function newfeatures = euChris_calcNormalizedFeatureResponse( ...
%   oldfeatures, oldfield, normfield, baselinefield, ...
%   case_compare_lut, casefield, matchfields )
%
% This function normalizes responses from the specified test cases against
% baseline responses from different test cases.
%
% An example use-case is normalizing phase-specific responses against
% the random-phase response.
%
% "oldfeatures" is a cell array containing one or more stimulation response
%   feature extraction structures, per CHRISSTIMFEATURES.txt.
% "oldfield" is the name of the structure field containing data to normalize.
% "normfield" is the name of the normalized structure field to create, or ''
%   to not store normalized data.
% "baselinefield" is the name of the field to store a copy of the baseline
%   data in, or '' to not store baseline data.
% "case_compare_lut" is a 2xNcases cell array. The first row contains labels
%   of test cases to be normalized, and the second row contains corresponding
%   labels of baseline cases to normalize against.
% "casefield" is the name of the field containing the case label.
% "matchfields" is a cell array containing zero or more field names (such as
%   'session' or 'probe')that have to match between cases that are normalized
%   or averaged.
%
% "newfeatures" is a copy of "oldfeatures". Responses that could be
%   normalized have a new field added (with the specified name). This is a
%   matrix with the same dimensions as the source field containing the
%   that record's response normalized by the baseline case's response
%   (averaged across compatible records).


newfeatures = oldfeatures;



%
% First pass: Walk through the dataset and build identity and baseline
% key tuples for each element.

selfkeylut = {};
basekeylut = {};

matchfields = unique(matchfields);

compare_lut_test = case_compare_lut(1,:);
compare_lut_base = case_compare_lut(2,:);

for didx = 1:length(oldfeatures)

  thisrec = oldfeatures{didx};

  thismatchkey = '';
  for midx = 1:length(matchfields)
    thismatchkey = [ thismatchkey '_' thisrec.(matchfields{midx}) ];
  end

  thiscase = thisrec.(casefield);

  selfkeylut{didx} = [ thiscase thismatchkey ];

  compareidx = find(strcmp(thiscase, compare_lut_test));

  if isempty(compareidx)
    basekeylut{didx} = '';
  else
    basekeylut{didx} = [ compare_lut_base{compareidx} thismatchkey ];
  end

end



%
% Second pass: Build normalized datasets.

basedatakeys = unique(basekeylut);
basedatavalues = {};

for kidx = 1:length(basedatakeys)

  thisaverage = [];
  thiscount = 0;
  thiskey = basedatakeys{kidx};

  for didx = 1:length(oldfeatures)
    if strcmp(selfkeylut{didx}, thiskey)
      thisdata = oldfeatures{didx}.(oldfield);

      if isempty(thisaverage)
        thisaverage = zeros(size(thisdata));
      end

      thisaverage = thisaverage + thisdata;
      thiscount = thiscount + 1;
    end
  end

  if thiscount > 0
    thisaverage = thisaverage / thiscount;
  end

  basedatavalues{kidx} = thisaverage;

end



%
% Third pass: Normalize anything that can be normalized.

for didx = 1:length(newfeatures)
  if ~isempty(basekeylut{didx})

    thisdata = newfeatures{didx}.(oldfield);

    thisbasekey = basekeylut{didx};
    thisbaseidx = find(strcmp(thisbasekey, basedatakeys));

    thisaverage = basedatavalues{thisbaseidx};

    if ~isempty(thisaverage)
      if ~isempty(normfield)
        newfeatures{didx}.(normfield) = thisdata ./ thisaverage;
      end

      if ~isempty(baselinefield)
        newfeatures{didx}.(baselinefield) = thisaverage;
      end
    end

  end
end



% Done.
end


%
% This is the end of the file
