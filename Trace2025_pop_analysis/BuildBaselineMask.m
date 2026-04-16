function baselineMask = BuildBaselineMask(FeatureData, FeatureNames, soundFrames, fps, GroupType, Opts, hasDistractor)

nFrames = size(FeatureData,1);
baselineMask = false(nFrames,1);

soundOn = soundFrames(1);
baseLen = round(Opts.BaseLineSec * fps);

switch lower(GroupType)
    case {'delay','trace'}
        startIdx = max(1, soundOn - baseLen);
        endIdx   = soundOn - 1;
        if endIdx >= startIdx
            baselineMask(startIdx:endIdx) = true;
        end

    case 'distractor'
        % candidate baseline with запас: 60 s before sound
        candidateLenSec = 60;
        candidateLen = round(candidateLenSec * fps);

        startIdx = max(1, soundOn - candidateLen);
        endIdx   = soundOn - 1;

        if endIdx < startIdx
            return;
        end

        candidate = false(nFrames,1);
        candidate(startIdx:endIdx) = true;

        if hasDistractor
            dIdx = find(strcmp(FeatureNames, 'distractor'), 1);
            dMask = logical(FeatureData(:, dIdx));

            % remove distractor itself
            candidate(dMask) = false;

            % remove 3 s after each distractor bout
            onsets = find(diff([0; dMask]) == 1); %#ok<NASGU>
            offsets = find(diff([dMask; 0]) == -1);

            postFrames = round(Opts.DistrPostSec * fps);
            for i = 1:numel(offsets)
                postStart = offsets(i) + 1;
                postEnd = min(nFrames, offsets(i) + postFrames);
                candidate(postStart:postEnd) = false;
            end
        end

        % priority:
        % 1) one continuous 20 s chunk, searching from right to left
        % 2) otherwise two 10 s chunks, also from right to left
        baselineMask = PickBestDistractorBaseline(candidate, fps, Opts);

    otherwise
        error('Unknown GroupType: %s', GroupType);
end
end