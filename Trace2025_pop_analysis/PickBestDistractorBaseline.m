function baselineMask = PickBestDistractorBaseline(candidateMask, fps, Opts)

baselineMask = false(size(candidateMask));

fullLen = round(Opts.BaseLineSec * fps);                 % usually 20 s
chunkLen = round(Opts.DistrBaselineChunkSec * fps);      % usually 10 s

% -------- Step 1: try to find one continuous 20 s chunk from right to left
cc = bwconncomp(candidateMask);
bestChunk = [];

for i = 1:cc.NumObjects
    idx = cc.PixelIdxList{i};
    if numel(idx) >= fullLen
        % take the last fullLen frames of this segment (closest to sound)
        tempChunk = idx(end-fullLen+1:end);

        if isempty(bestChunk) || tempChunk(end) > bestChunk(end)
            bestChunk = tempChunk;
        end
    end
end

if ~isempty(bestChunk)
    baselineMask(bestChunk) = true;
    return;
end

% -------- Step 2: otherwise find two 10 s chunks from right to left
chunks = {};

for i = 1:cc.NumObjects
    idx = cc.PixelIdxList{i};
    if numel(idx) >= chunkLen
        % from one long clean segment we may take multiple 10 s chunks from right to left
        nSub = floor(numel(idx) / chunkLen);
        for k = 1:nSub
            endPos = numel(idx) - (k-1)*chunkLen;
            startPos = endPos - chunkLen + 1;
            chunks{end+1} = idx(startPos:endPos); %#ok<AGROW>
        end
    end
end

if isempty(chunks)
    return;
end

% sort candidate chunks by end position descending (right to left)
chunkEnds = cellfun(@(x)x(end), chunks);
[~, ord] = sort(chunkEnds, 'descend');
chunks = chunks(ord);

% take first two
nTake = min(2, numel(chunks));
for i = 1:nTake
    baselineMask(chunks{i}) = true;
end
end