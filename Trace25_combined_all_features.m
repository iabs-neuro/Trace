clear; clc;

%% paths
MotPath  = 'e:\Projects\Trace\BehaviorData\4_MotInd\';
FrzPath  = 'e:\Projects\Trace\BehaviorData\5_Freezing\';
DLCPath  = 'e:\Projects\Trace\BehaviorData\3_DLC\';
StimPath = 'e:\Projects\Trace\BehaviorData\6_Stimulus\';
OutPath  = 'e:\Projects\Trace\BehaviorData\7_Features\';

if ~exist(OutPath, 'dir')
    mkdir(OutPath);
end

%% use freezing files as reference list of sessions
files = dir(fullfile(FrzPath, '*_Freezing_*.csv'));

fprintf('Found %d sessions\n', numel(files));

for i = 1:numel(files)
    frzFile = files(i).name;

    tok = regexp(frzFile, '^(.*)_Freezing_.*\.csv$', 'tokens', 'once');
    if isempty(tok)
        fprintf('Skip: cannot parse session name from %s\n', frzFile);
        continue;
    end
    SessionName = tok{1};   % e.g. J01_trace_1D

    fprintf('\nProcessing %s\n', SessionName);

    %% construct matching filenames
    motFile  = fullfile(MotPath,  [SessionName '_MotionIndex_13_5_18_15.csv']);
    stimFile = fullfile(StimPath, [SessionName '_features.csv']);
    dlcFile  = fullfile(DLCPath,  [SessionName 'DLC_resnet50_RNF_2022Nov28shuffle1_300000.csv']);
    frzFull  = fullfile(FrzPath,  frzFile);

    if ~isfile(motFile)
        fprintf('  Missing MotInd file: %s\n', motFile);
        continue;
    end
    if ~isfile(stimFile)
        fprintf('  Missing Stimulus file: %s\n', stimFile);
        continue;
    end
    if ~isfile(dlcFile)
        fprintf('  Missing DLC file: %s\n', dlcFile);
        continue;
    end

    %% read motion index
    Tmot = readtable(motFile);
    if width(Tmot) < 1
        fprintf('  MotInd file has no columns: %s\n', motFile);
        continue;
    end
    motionIndex = Tmot{:,1};

    %% read freezing
    Tfrz = readtable(frzFull);
    if width(Tfrz) < 1
        fprintf('  Freezing file has no columns: %s\n', frzFull);
        continue;
    end
    freezing = Tfrz{:,1};

    %% read DLC
    Tdlc = readtable(dlcFile, 'ReadVariableNames', true);

    if width(Tdlc) < 2
        fprintf('  DLC file has fewer than 2 columns: %s\n', dlcFile);
        continue;
    end

    % take first two columns as x and y
    x_all = Tdlc{:,5};
    y_all = Tdlc{:,6};

    %% read stimulus
    Tstim = readtable(stimFile);

    %% reference length
    nRef = numel(freezing);

    if numel(motionIndex) ~= nRef
        fprintf('  WARNING: motionIndex length (%d) ~= freezing length (%d)\n', numel(motionIndex), nRef);
        nRef2 = min(numel(motionIndex), nRef);
        motionIndex = motionIndex(1:nRef2);
        freezing = freezing(1:nRef2);
        nRef = nRef2;
    end

    %% DLC expected to be longer by 1 frame
    nDLC = numel(x_all);

    if nDLC == nRef + 1
        x = x_all(2:end);
        y = y_all(2:end);
    else
        fprintf('  WARNING: DLC length is %d, expected %d (= nRef+1)\n', nDLC, nRef + 1);

        if nDLC >= nRef + 1
            x = x_all(2:nRef+1);
            y = y_all(2:nRef+1);
            fprintf('  DLC was cropped from start to match reference length\n');
        elseif nDLC == nRef
            x = x_all;
            y = y_all;
            fprintf('  DLC already has same length as reference, no initial crop applied\n');
        else
            fprintf('  DLC shorter than reference, cropping all sources to common minimum\n');
            nCommon = min([nRef, nDLC, height(Tstim)]);
            x = x_all(1:nCommon);
            y = y_all(1:nCommon);
            freezing = freezing(1:nCommon);
            motionIndex = motionIndex(1:nCommon);
            Tstim = Tstim(1:nCommon,:);
            nRef = nCommon;
        end
    end

    %% make final length equal across all sources
    nFinal = min([numel(x), numel(y), numel(freezing), numel(motionIndex), height(Tstim)]);

    if numel(x) ~= nFinal || numel(freezing) ~= nFinal || height(Tstim) ~= nFinal
        fprintf('  WARNING: final length mismatch, cropped all to %d rows\n', nFinal);
    end

    x = x(1:nFinal);
    y = y(1:nFinal);
    freezing = freezing(1:nFinal);
    motionIndex = motionIndex(1:nFinal);
    Tstim = Tstim(1:nFinal,:);

    %% final table
    Tout = table(x, y, freezing, motionIndex, ...
        'VariableNames', {'x','y','freezing','motionIndex'});

    Tout = [Tout Tstim];

    %% save
    outFile = fullfile(OutPath, [SessionName '_features.csv']);
    writetable(Tout, outFile);

    fprintf('  Saved: %s | rows=%d | cols=%d\n', outFile, height(Tout), width(Tout));
end

disp('Done.');