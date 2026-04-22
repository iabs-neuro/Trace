function BuildGroupLevelSummaryFromMatFiles(popAnalysisDir)
% Build group-level tables/plots from already computed *_PopAnalysis.mat files.
%
% Usage:
%   BuildGroupLevelSummaryFromMatFiles('e:\Projects\Trace\BehaviorData\PopAnalysis')
%
% Notes:
% - Reads SessionRes from *_PopAnalysis.mat
% - If matching *_PopCache.mat exists, it also loads TraceNorm and enables
%   trace-dependent group heatmaps/curves.
% - If cache files are missing, count/percent tables are still generated.

if nargin < 1 || isempty(popAnalysisDir)
    error('Provide folder with *_PopAnalysis.mat files');
end

files = dir(fullfile(popAnalysisDir, 'Trace_*_*D_PopAnalysis.mat'));
if isempty(files)
    error('No *_PopAnalysis.mat files found in %s', popAnalysisDir);
end

Results = struct();
SessionCache = struct([]);

for i = 1:numel(files)
    p = fullfile(files(i).folder, files(i).name);
    L = load(p, 'SessionRes');
    if ~isfield(L, 'SessionRes') || isempty(L.SessionRes)
        fprintf('Skip (no SessionRes): %s\n', files(i).name);
        continue;
    end
    S = L.SessionRes;
    Results.(matlab.lang.makeValidName(S.SessionID)) = S;

    cacheFile = fullfile(files(i).folder, [S.SessionID '_PopCache.mat']);
    if isfile(cacheFile)
        C = load(cacheFile, 'TraceNorm', 'FeatureData', 'FeatureNames', 'fpsUsed');
        if isfield(C, 'TraceNorm')
            iS = numel(SessionCache) + 1;
            SessionCache(iS).SessionRes = S;
            SessionCache(iS).TraceNorm = C.TraceNorm;
            if isfield(C, 'FeatureData'); SessionCache(iS).FeatureData = C.FeatureData; else, SessionCache(iS).FeatureData = []; end
            if isfield(C, 'FeatureNames'); SessionCache(iS).FeatureNames = C.FeatureNames; else, SessionCache(iS).FeatureNames = {}; end
            if isfield(C, 'fpsUsed'); SessionCache(iS).fps = C.fpsUsed; else, SessionCache(iS).fps = S.fps; end
        end
    end
end

if isempty(fieldnames(Results))
    error('No valid SessionRes loaded from %s', popAnalysisDir);
end

Opts = struct();
BuildGroupLevelSummary(Results, SessionCache, popAnalysisDir, Opts);
disp('Group-level summary from MAT files is complete.');
end
