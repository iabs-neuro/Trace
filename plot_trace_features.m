clear; clc;

%% path
InPath = 'e:\Projects\Trace\BehaviorData\6_Stimulus\';

%% choose file
[file, path] = uigetfile(fullfile(InPath, '*_features.csv'), 'Select feature table');
if isequal(file,0)
    return;
end

%% read table
T = readtable(fullfile(path, file));
X = table2array(T);
FeatureNames = T.Properties.VariableNames;

%% plot
figure;
imagesc(X');
colormap(gray);
xlabel('Frame');
ylabel('Feature');
title(strrep(file, '_', '\_'));

yticks(1:numel(FeatureNames));
yticklabels(FeatureNames);
set(gca, 'TickLabelInterpreter', 'none');