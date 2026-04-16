function tf = IsResponsive(baseVals, respVals, Opts)

baseVals = baseVals(:)';
respVals = respVals(:)';

if isempty(baseVals) || isempty(respVals)
    tf = false;
    return;
end

% Require increase
if median(respVals) <= median(baseVals)
    tf = false;
    return;
end

% Mann-Whitney: response should be greater than baseline
pU = ranksum(respVals, baseVals, 'tail', 'right');
if pU >= Opts.p_value
    tf = false;
    return;
end

% Bootstrap / permutation on difference of means
realDiff = mean(respVals) - mean(baseVals);
pool = [baseVals, respVals];
nBase = numel(baseVals);
nResp = numel(respVals);

surDiff = zeros(Opts.NumIter,1);
for k = 1:Opts.NumIter
    idx = randperm(numel(pool));
    b = pool(idx(1:nBase));
    r = pool(idx(nBase+1:nBase+nResp));
    surDiff(k) = mean(r) - mean(b);
end

pBoot = (sum(surDiff >= realDiff) + 1) / (Opts.NumIter + 1);

tf = pBoot < Opts.p_value;
end
