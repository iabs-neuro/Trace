function outMask = PickFirstTwoCleanChunks(candidateMask, chunkLen)
outMask = false(size(candidateMask));

cc = bwconncomp(candidateMask);
nFound = 0;

for i = 1:cc.NumObjects
    idx = cc.PixelIdxList{i};
    if numel(idx) >= chunkLen
        outMask(idx(1:chunkLen)) = true;
        nFound = nFound + 1;
        if nFound == 2
            break;
        end
    end
end
end