clear; clc;

%% ================== SETTINGS ==================
root = 'e:\Projects\Trace\BehaviorData\';

Paths.Features = fullfile(root, '7_Features');
Paths.Traces   = fullfile(root, '6_Traces');
Paths.TimeStamps = fullfile(root, '0_TimeStamps');
Paths.Out      = fullfile(root, 'PopAnalysis');

if ~exist(Paths.Out, 'dir')
    mkdir(Paths.Out);
end

Opts.NumIter = 1000;
Opts.p_value = 0.05;
Opts.NormWay = 'MADscore';      % 'none' | 'zscore' | 'MADscore'
Opts.BinMode = '1s';          % 'none' | '1s'
Opts.BinSizeSec = 1;

Opts.BaseLineSec = 20;
Opts.USWindowSec = 6;
Opts.DistrPostSec = 3;          % remove 3 s after distractor from baseline
Opts.DistrBaselineChunkSec = 10; % first two clean 10 s baseline pieces
Opts.MinTrialsResponsive = 3;   % user-defined N out of 7
Opts.MakePlots = true;
Opts.PlotPadSec = 10;

% session-level mode 1 = minimum N trials
% session-level mode 2 = mean across trials
Opts.SessionModeList = {'MinTrials', 'MeanAcrossTrials'};

MouseGroups.Delay      = {'J02','J07','J13','J19','J26','J27','J29','J52','J57','J58'};
MouseGroups.Trace      = {'J01','J03','J05','J10','J18','J20','J24','J53'};
MouseGroups.Distractor = {'J06','J12','J14','J17','J25','J54','J55','J59','J61'};

%% ================== FILE LIST ==================
featureFiles = dir(fullfile(Paths.Features, 'Trace_*_*D_features.csv'));
fprintf('Found %d feature files\n', numel(featureFiles));
if isempty(featureFiles)
    error('No feature files found in %s', Paths.Features);
end

Results = struct();

for iFile = 1:numel(featureFiles)
    featureName = featureFiles(iFile).name;
    featurePath = fullfile(Paths.Features, featureName);

    tok = regexp(featureName, '^Trace_(J\d+)_(\dD)_features\.csv$', 'tokens', 'once');
    if isempty(tok)
        fprintf('Skip: %s\n', featureName);
        continue;
    end

    MouseID = tok{1};
    DayID   = tok{2};
    SessionID = sprintf('Trace_%s_%s', MouseID, DayID);

    fprintf('\n==============================\n');
    fprintf('Processing %s\n', SessionID);

    % -------- determine group --------
    if ismember(MouseID, MouseGroups.Delay)
        GroupType = 'delay';
    elseif ismember(MouseID, MouseGroups.Trace)
        GroupType = 'trace';
    elseif ismember(MouseID, MouseGroups.Distractor)
        GroupType = 'distractor';
    else
        fprintf('Unknown group for %s\n', MouseID);
        continue;
    end

    % -------- load features --------
    Tfeat = readtable(featurePath);

    % -------- load traces --------
    % expected naming style: Trace_J01_1D_traces.csv
    tracePath = fullfile(Paths.Traces, [SessionID '_traces.csv']);
    if ~isfile(tracePath)
        fprintf('Missing traces file: %s\n', tracePath);
        continue;
    end
    Ttr = readtable(tracePath);

    % choose trace columns (drop obvious meta/time columns when present)
    trNames = Ttr.Properties.VariableNames;
    isNumericCol = varfun(@isnumeric, Ttr, 'OutputFormat', 'uniform');
    isMetaCol = startsWith(lower(trNames), {'time','timestamp','frame','index'});
    keepCols = isNumericCol & ~isMetaCol;

    if ~any(keepCols)
        % fallback for unknown naming conventions: keep all numeric columns
        keepCols = isNumericCol;
    end

    TraceRaw = Ttr{:, keepCols};

    %% -------- load timestamps --------
    tsPath = fullfile(Paths.TimeStamps, [SessionID '_timestamp.csv']);
    if ~isfile(tsPath)
        fprintf('Missing timestamp file: %s\n', tsPath);
        continue;
    end

    Tts = readtable(tsPath);

    if width(Tts) < 2
        fprintf('Timestamp file has fewer than 2 columns: %s\n', tsPath);
        continue;
    end

    timeVec_ms = Tts{:,2};  % second column = Time Stamp (ms)

    nTrace = size(TraceRaw,1);
    nTime  = numel(timeVec_ms);
    nFeat  = height(Tfeat);
    
    % timestamps should match traces
    if nTime ~= nTrace
        fprintf('WARNING: timestamp rows (%d) ~= trace rows (%d) in %s\n', ...
            nTime, nTrace, SessionID);
        
        nCommon = min(nTime, nTrace);
        timeVec_ms = timeVec_ms(1:nCommon);
        TraceRaw = TraceRaw(1:nCommon,:);
        nTrace = nCommon;
        
        fprintf('Cropped traces/timestamps to %d rows\n', nCommon);
    end
    
    % features are often slightly longer -> resample features to trace length
    if nFeat ~= nTrace
        fprintf('WARNING: feature rows (%d) ~= trace rows (%d) in %s\n', ...
            nFeat, nTrace, SessionID);
        
        Tfeat = ResampleFeatureTableToLength(Tfeat, nTrace);
        
        fprintf('Resampled features: %d -> %d rows\n', nFeat, nTrace);
    end

    fps = EstimateFPS(timeVec_ms);
    fprintf('Estimated calcium FPS from timestamp file = %.4f\n', fps);

    %% -------- optional temporal binning --------
    if strcmpi(Opts.BinMode, '1s')
        [TraceData, FeatureData, FeatureNames, fpsUsed] = BinSessionToSeconds(TraceRaw, Tfeat, fps, Opts.BinSizeSec);
    else
        TraceData = TraceRaw;
        FeatureData = table2array(Tfeat);
        FeatureNames = Tfeat.Properties.VariableNames;
        fpsUsed = fps;
    end

    %% -------- normalize traces --------
    TraceNorm = NormalizeTraces(TraceData, Opts.NormWay);

    %% -------- analyze session --------
    SessionRes = AnalyzeOneSession(TraceNorm, FeatureData, FeatureNames, fpsUsed, GroupType, DayID, Opts);

    SessionRes.MouseID = MouseID;
    SessionRes.DayID = DayID;
    SessionRes.GroupType = GroupType;
    SessionRes.SessionID = SessionID;
    SessionRes.FeatureFile = featureName;
    SessionRes.TraceFile = [SessionID '_traces.csv'];
    SessionRes.TimeStampFile = [SessionID '_timestamp.csv'];
    SessionRes.FPS = fps;
    SessionRes.FPS_used = fpsUsed;

    Results.(matlab.lang.makeValidName(SessionID)) = SessionRes;

    save(fullfile(Paths.Out, [SessionID '_PopAnalysis.mat']), 'SessionRes');
    fprintf('Saved %s\n', fullfile(Paths.Out, [SessionID '_PopAnalysis.mat']));

    if Opts.MakePlots
        RunPopulationVisualization(SessionRes, TraceNorm, FeatureData, FeatureNames, fpsUsed, Paths.Out, Opts);
    end
end

save(fullfile(Paths.Out, 'AllSessions_PopAnalysis.mat'), 'Results', 'Opts', 'MouseGroups');
if Opts.MakePlots
    BuildGroupLevelSummary(Results, Paths.Out);
end
disp('Done.');
