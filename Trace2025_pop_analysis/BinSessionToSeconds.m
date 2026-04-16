function [TraceB, FeatureB, FeatureNames, fpsOut] = BinSessionToSeconds(TraceRaw, Tfeat, fpsIn, binSec)

% Bin calcium traces and binary features into fixed time bins.
% Works correctly for non-integer FPS, e.g. 29.78.

nFrames = size(TraceRaw,1);
FeatArr = table2array(Tfeat);
FeatureNames = Tfeat.Properties.VariableNames;

% time of each frame in seconds, starting at 0
timeVec = (0:nFrames-1)' / fpsIn;

% bin edges in seconds
tEnd = timeVec(end);
edges = 0:binSec:(floor(tEnd/binSec)*binSec + binSec);
nBins = numel(edges) - 1;

TraceB = zeros(nBins, size(TraceRaw,2));
FeatureB = zeros(nBins, size(FeatArr,2));

for b = 1:nBins
    idx = timeVec >= edges(b) & timeVec < edges(b+1);

    if ~any(idx)
        continue;
    end

    TraceB(b,:) = mean(TraceRaw(idx,:), 1, 'omitnan');
    FeatureB(b,:) = any(FeatArr(idx,:) > 0, 1);
end

fpsOut = 1 / binSec;
end