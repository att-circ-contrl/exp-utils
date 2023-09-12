function [ artmethod artconfig ] = ...
  euChris_getArtifactConfigFromSignalConfig( signalconfig )

% function [ artmethod artconfig ] = ...
%   euChris_getArtifactConfigFromSignalConfig( signalconfig )
%
% This extracts the appropriate artifact rejection configuration structure
% from a signal configuration structure.
%
% "signalconfig" is a signal configuration structure, per SIGNALCONFIG.txt.
%
% "artmethod" is an artifact rejection method, per ARTIFACTCONFIG.txt.
% "artconfig" is an artifact rejection configuration structure, per
%   ARTIFACTCONFING.txt.


artmethod = 'none';
artconfig = struct();

if isfield(signalconfig, 'artifact_method')
  artmethod = signalconfig.artifact_method;
end

if strcmp('sigma', artmethod)
  artconfig = signalconfig.artparams_sigma;
elseif strcmp('expknown', artmethod)
  artconfig = signalconfig.artparams_expknown;
elseif strcmp('expguess', artmethod)
  artconfig = signalconfig.artparams_expguess;
end


% Done.
end


%
% This is the end of the file.
