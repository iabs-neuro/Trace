function MeanRes = ComputeMeanAcrossTrials(TraceNorm, TrialRes, validTrials, Opts)

nCells = size(TraceNorm,2);

CSresp = false(1,nCells);
TRresp = false(1,nCells);
USresp = false(1,nCells);

% Restrict MeanAcrossTrials to neurons that were responsive at least once
% at trial-level for the corresponding interval.
trialCS = false(1,nCells);
trialTR = false(1,nCells);
trialUS = false(1,nCells);
for t = validTrials
    trialCS = trialCS | TrialRes(t).CS;
    trialTR = trialTR | TrialRes(t).Trace;
    trialUS = trialUS | TrialRes(t).US;
end

% session-level responsiveness from trial-averaged activity:
% for each trial, compute mean activity in baseline/response windows,
% then apply the same statistics across trials.
for c = find(trialCS)
    baseAll = [];
    csAll = [];
    for t = validTrials
        baseVals = TraceNorm(TrialRes(t).BaselineMask, c);
        csVals   = TraceNorm(TrialRes(t).SoundMask, c);

        if ~isempty(baseVals)
            baseAll = [baseAll; mean(baseVals, 'omitnan')];
        end
        if ~isempty(csVals)
            csAll = [csAll; mean(csVals, 'omitnan')];
        end
    end

    if ~isempty(baseAll) && ~isempty(csAll)
        CSresp(c) = IsResponsive(baseAll, csAll, Opts);
    end
end

for c = find(trialTR)
    baseAll = [];
    trAll = [];
    for t = validTrials
        baseVals = TraceNorm(TrialRes(t).BaselineMask, c);
        trVals   = TraceNorm(TrialRes(t).TraceMask, c);
        if ~isempty(baseVals)
            baseAll = [baseAll; mean(baseVals, 'omitnan')];
        end
        if ~isempty(trVals)
            trAll = [trAll; mean(trVals, 'omitnan')];
        end
    end
    if ~isempty(baseAll) && ~isempty(trAll)
        TRresp(c) = IsResponsive(baseAll, trAll, Opts);
    end
end

for c = find(trialUS)
    baseAll = [];
    usAll = [];
    for t = validTrials
        baseVals = TraceNorm(TrialRes(t).BaselineMask, c);
        if ~isempty(baseVals)
            baseAll = [baseAll; mean(baseVals, 'omitnan')];
        end
        if any(TrialRes(t).USMask)
            usVals = TraceNorm(TrialRes(t).USMask, c);
            if ~isempty(usVals)
                usAll = [usAll; mean(usVals, 'omitnan')];
            end
        end
    end
    if ~isempty(baseAll) && ~isempty(usAll)
        USresp(c) = IsResponsive(baseAll, usAll, Opts);
    end
end

MeanRes.CS = CSresp;
MeanRes.Trace = TRresp;
MeanRes.US = USresp;
MeanRes.CSTrace = CSresp & TRresp;
MeanRes.CSOnly = CSresp & ~TRresp;
MeanRes.TraceOnly = TRresp & ~CSresp;
end
