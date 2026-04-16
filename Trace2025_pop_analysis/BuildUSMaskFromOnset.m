function USMask = BuildUSMaskFromOnset(binaryStimMask, fps, usWindowSec)
binaryStimMask = logical(binaryStimMask(:));
nFrames = numel(binaryStimMask);
USMask = false(nFrames,1);

onsets = find(diff([0; binaryStimMask]) == 1);
usLen = round(usWindowSec * fps);

for i = 1:numel(onsets)
    st = onsets(i);
    en = min(nFrames, st + usLen - 1);
    USMask(st:en) = true;
end
end