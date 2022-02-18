function newdata = doCommonAverageReference( olddata, commongroups )

% function newdata = doCommonAverageReference( olddata, commongroups )
%
% This re-references selected groups of channels in a Field Trip dataset.
%
% "olddata" is the Field Trip dataset to process.
% "commongroups" is a cell array containing signal groups. Each signal group
%   is a cell array containing Field Trip channel labels for the group's
%   signals.
%
% "newdata" is a copy of "olddata" with the group average subtracted from
%   all signals that are members of a group.

newdata = olddata;

groupcount = length(commongroups);
chancount = length(newdata.label);

if groupcount > 0
  for tidx = 1:length(newdata.trial)

    thistrial = newdata.trial{tidx};

    sampcount = size(thistrial);
    sampcount = sampcount(2);

    for gidx = 1:groupcount
      thisgroup = commongroups{gidx};

      thiscommon = zeros(1, sampcount);
      thiscount = 0;

      for cidx = 1:chancount
        thislabel = newdata.label{cidx};
        if ismember(thislabel, thisgroup)
          thiscount = thiscount + 1;
          thiscommon = thiscommon + thistrial(cidx,:);
        end
      end

      if thiscount > 0
        thiscommon = thiscommon / thiscount;
        for cidx = 1:chancount
          thislabel = newdata.label{cidx};
          if ismember(thislabel, thisgroup)
            thistrial(cidx,:) = thistrial(cidx,:) - thiscommon;
          end
        end
      end
    end

    newdata.trial{tidx} = thistrial;

  end
end


% Done.

end


%
% This is the end of the file.
