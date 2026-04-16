function SessionRes = AnalyzeOneSession(TraceNorm, FeatureData, FeatureNames, fps, GroupType, DayID, Opts)

nFrames = size(TraceNorm,1);
nCells  = size(TraceNorm,2);
nTrials = 7;

TrialRes = struct([]);

% ---- define US source for 1D ----
shockIdx = find(strcmp(FeatureNames, 'shock'), 1);
soundShockIdx = find(strcmp(FeatureNames, 'sound_shock'), 1);
distractorIdx = find(strcmp(FeatureNames, 'distractor'), 1);

hasShock = ~isempty(shockIdx) && any(FeatureData(:, shockIdx) > 0);
hasSoundShock = ~isempty(soundShockIdx) && any(FeatureData(:, soundShockIdx) > 0);
hasDistractor = ~isempty(distractorIdx) && any(FeatureData(:, distractorIdx) > 0);

for trial = 1:nTrials
    soundName = sprintf('sound%d', trial);
    traceName = sprintf('trace%d', trial);

    soundIdx = find(strcmp(FeatureNames, soundName), 1);
    traceIdx = find(strcmp(FeatureNames, traceName), 1);

    if isempty(soundIdx) || isempty(traceIdx)
        fprintf('Trial %d skipped: sound/trace columns not found\n', trial);
        continue;
    end

    soundMask = logical(FeatureData(:, soundIdx));
    traceMask = logical(FeatureData(:, traceIdx));

    if ~any(soundMask)
        fprintf('Trial %d skipped: empty sound window\n', trial);
        continue;
    end

    soundFrames = find(soundMask);
    traceFrames = find(traceMask);

    % -------- baseline --------
    baselineMask = BuildBaselineMask(FeatureData, FeatureNames, soundFrames, fps, GroupType, Opts, hasDistractor);

    if sum(baselineMask) < round(5 * fps)
        fprintf('WARNING: trial %d baseline is too short (%d frames)\n', trial, sum(baselineMask));
    end

    % -------- US mask (trial-specific) --------
    USMask = false(nFrames,1);
    if strcmpi(DayID, '1D')
        trialStart = soundFrames(1);
        if ~isempty(traceFrames)
            trialEnd = min(nFrames, traceFrames(end) + round(Opts.USWindowSec * fps));
        else
            trialEnd = min(nFrames, soundFrames(end) + round(Opts.USWindowSec * fps));
        end

        trialRegion = false(nFrames,1);
        trialRegion(trialStart:trialEnd) = true;

        switch GroupType
            case 'delay'
                if hasSoundShock
                    usSource = logical(FeatureData(:, soundShockIdx)) & trialRegion;
                    USMask = BuildUSMaskFromOnset(usSource, fps, Opts.USWindowSec);
                end
            case {'trace','distractor'}
                if hasShock
                    usSource = logical(FeatureData(:, shockIdx)) & trialRegion;
                    USMask = BuildUSMaskFromOnset(usSource, fps, Opts.USWindowSec);
                end
        end
    end

    % -------- cell-wise tests --------
    CSresp = false(1,nCells);
    TRresp = false(1,nCells);
    USresp = false(1,nCells);

    for c = 1:nCells
        baseVals = TraceNorm(baselineMask, c);

        csVals = TraceNorm(soundMask, c);
        trVals = TraceNorm(traceMask, c);

        if ~isempty(baseVals) && ~isempty(csVals)
            CSresp(c) = IsResponsive(baseVals, csVals, Opts);
        end
        if ~isempty(baseVals) && ~isempty(trVals)
            TRresp(c) = IsResponsive(baseVals, trVals, Opts);
        end

        if any(USMask)
            usVals = TraceNorm(USMask, c);
            if ~isempty(baseVals) && ~isempty(usVals)
                USresp(c) = IsResponsive(baseVals, usVals, Opts);
            end
        end
    end

    CSTrace = CSresp & TRresp;
    CSOnly  = CSresp & ~TRresp;
    TROnly  = TRresp & ~CSresp;

    TrialRes(trial).Trial = trial;
    TrialRes(trial).CS = CSresp;
    TrialRes(trial).Trace = TRresp;
    TrialRes(trial).US = USresp;
    TrialRes(trial).CSTrace = CSTrace;
    TrialRes(trial).CSOnly = CSOnly;
    TrialRes(trial).TraceOnly = TROnly;

    TrialRes(trial).Counts.CS = sum(CSresp);
    TrialRes(trial).Counts.Trace = sum(TRresp);
    TrialRes(trial).Counts.US = sum(USresp);
    TrialRes(trial).Counts.CSTrace = sum(CSTrace);
    TrialRes(trial).Counts.CSOnly = sum(CSOnly);
    TrialRes(trial).Counts.TraceOnly = sum(TROnly);

    TrialRes(trial).BaselineMask = baselineMask;
    TrialRes(trial).SoundMask = soundMask;
    TrialRes(trial).TraceMask = traceMask;
    TrialRes(trial).USMask = USMask;
end

% -------- session-level populations --------
validTrials = [];
for t = 1:numel(TrialRes)
    if isfield(TrialRes(t), 'Trial') && ~isempty(TrialRes(t).Trial)
        validTrials(end+1) = t; %#ok<AGROW>
    end
end
if isempty(validTrials)
    SessionRes = struct();
    return;
end

% matrix: trials x cells
CSmat       = vertcat(TrialRes(validTrials).CS);
TRmat       = vertcat(TrialRes(validTrials).Trace);
USmat       = vertcat(TrialRes(validTrials).US);
CSTRmat     = vertcat(TrialRes(validTrials).CSTrace);
CSOnlyMat   = vertcat(TrialRes(validTrials).CSOnly);
TROnlyMat   = vertcat(TrialRes(validTrials).TraceOnly);

SessionRes.TrialRes = TrialRes;
SessionRes.nCells = nCells;
SessionRes.nTrialsAnalyzed = numel(validTrials);
SessionRes.fps = fps;
SessionRes.FeatureNames = FeatureNames;

% ---- Mode 1: minimum N trials ----
N = Opts.MinTrialsResponsive;
SessionRes.SessionLevel.MinTrials.N = N;

SessionRes.SessionLevel.MinTrials.CS        = sum(CSmat,1)     >= N;
SessionRes.SessionLevel.MinTrials.Trace     = sum(TRmat,1)     >= N;
SessionRes.SessionLevel.MinTrials.US        = sum(USmat,1)     >= N;
SessionRes.SessionLevel.MinTrials.CSTrace   = sum(CSTRmat,1)   >= N;
SessionRes.SessionLevel.MinTrials.CSOnly    = sum(CSOnlyMat,1) >= N;
SessionRes.SessionLevel.MinTrials.TraceOnly = sum(TROnlyMat,1) >= N;

% ---- Mode 2: mean across trials ----
MeanTrialRes = ComputeMeanAcrossTrials(TraceNorm, TrialRes, validTrials, Opts);

SessionRes.SessionLevel.MeanAcrossTrials = MeanTrialRes;

% ---- counts ----
fn = {'CS','Trace','US','CSTrace','CSOnly','TraceOnly'};
for k = 1:numel(fn)
    nm = fn{k};
    SessionRes.SessionLevel.MinTrials.Counts.(nm) = sum(SessionRes.SessionLevel.MinTrials.(nm));
    SessionRes.SessionLevel.MeanAcrossTrials.Counts.(nm) = sum(SessionRes.SessionLevel.MeanAcrossTrials.(nm));
end
end
