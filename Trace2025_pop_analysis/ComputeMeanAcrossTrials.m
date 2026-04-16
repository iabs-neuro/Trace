function MeanRes = ComputeMeanAcrossTrials(TraceNorm, TrialRes, validTrials, Opts)

nCells = size(TraceNorm,2);

CSresp = false(1,nCells);
TRresp = false(1,nCells);
USresp = false(1,nCells);

% concatenate windows across trials, then average by trial-wise pooling
for c = 1:nCells
    baseAll = [];
    csAll = [];
    trAll = [];
    usAll = [];

    for t = validTrials
        baseAll = [baseAll; TraceNorm(TrialRes(t).BaselineMask, c)];
        csAll   = [csAll;   TraceNorm(TrialRes(t).SoundMask, c)];
        trAll   = [trAll;   TraceNorm(TrialRes(t).TraceMask, c)];
        if any(TrialRes(t).USMask)
            usAll = [usAll; TraceNorm(TrialRes(t).USMask, c)];
        end
    end

    if ~isempty(baseAll) && ~isempty(csAll)
        CSresp(c) = IsResponsive(baseAll, csAll, Opts);
    end
    if ~isempty(baseAll) && ~isempty(trAll)
        TRresp(c) = IsResponsive(baseAll, trAll, Opts);
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