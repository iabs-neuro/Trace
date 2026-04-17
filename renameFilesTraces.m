clear; clc;

%% folder
FolderPath = 'e:\Projects\Trace\BehaviorData\7_Features\';

%% find files
files = dir(fullfile(FolderPath, '*_trace_*_features.csv'));

fprintf('Found %d files\n', numel(files));

for i = 1:numel(files)
    oldName = files(i).name;

    % parse names like J01_trace_1D_features.csv
    tok = regexp(oldName, '^(J\d+)_trace_(\dD)_features\.csv$', 'tokens', 'once');

    if isempty(tok)
        fprintf('Skip: %s\n', oldName);
        continue;
    end

    MouseID = tok{1};
    DayID   = tok{2};

    newName = sprintf('Trace_%s_%s_features.csv', MouseID, DayID);

    oldFull = fullfile(FolderPath, oldName);
    newFull = fullfile(FolderPath, newName);

    if isfile(newFull)
        fprintf('Target already exists, skip: %s\n', newName);
        continue;
    end

    movefile(oldFull, newFull);
    fprintf('Renamed: %s -> %s\n', oldName, newName);
end

disp('Done.');