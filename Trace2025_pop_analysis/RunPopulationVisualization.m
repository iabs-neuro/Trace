function RunPopulationVisualization(SessionRes, TraceNorm, FeatureData, FeatureNames, fps, outRoot, Opts)

if isempty(SessionRes) || ~isfield(SessionRes, 'TrialRes')
    return;
end

sessionDir = fullfile(outRoot, SessionRes.SessionID, 'plots');
if ~exist(sessionDir, 'dir')
    mkdir(sessionDir);
end

trialDir = fullfile(sessionDir, 'trial_level');
sessionLevelDir = fullfile(sessionDir, 'session_level');
if ~exist(trialDir, 'dir'); mkdir(trialDir); end
if ~exist(sessionLevelDir, 'dir'); mkdir(sessionLevelDir); end

popNames = {'CSTrace','CSOnly','TraceOnly','US'};
trialRows = {};

for t = 1:numel(SessionRes.TrialRes)
    if ~isfield(SessionRes.TrialRes(t), 'Trial') || isempty(SessionRes.TrialRes(t).Trial)
        continue;
    end

    tr = SessionRes.TrialRes(t);
    baseIdx = find(tr.BaselineMask);
    sndIdx = find(tr.SoundMask);
    trcIdx = find(tr.TraceMask);
    usIdx = find(tr.USMask);

    if isempty(sndIdx)
        continue;
    end

    if isempty(baseIdx)
        winStart = sndIdx(1);
    else
        winStart = min(baseIdx);
    end
    if isempty(trcIdx)
        winEnd = sndIdx(end);
    else
        winEnd = max(trcIdx);
    end

    pad = round(Opts.PlotPadSec * fps);
    idxWin = max(1, winStart - pad) : min(size(TraceNorm,1), winEnd + pad);
    timeRelSec = ((idxWin - sndIdx(1)) ./ fps)';

    maskSound = false(numel(idxWin),1);
    maskTrace = false(numel(idxWin),1);
    maskUS = false(numel(idxWin),1);
    maskBase = false(numel(idxWin),1);
    maskBase(ismember(idxWin, baseIdx)) = true;
    maskSound(ismember(idxWin, sndIdx)) = true;
    maskTrace(ismember(idxWin, trcIdx)) = true;
    maskUS(ismember(idxWin, usIdx)) = true;

    % (a) stacked + heatmap for each population
    for p = 1:numel(popNames)
        pop = popNames{p};
        idxCells = find(tr.(pop));
        X = TraceNorm(idxWin, idxCells)'; % neurons x time

        switch pop
            case {'CSTrace'}
                targetMask = maskSound | maskTrace;
            case 'CSOnly'
                targetMask = maskSound;
            case 'TraceOnly'
                targetMask = maskTrace;
            case 'US'
                targetMask = maskUS;
        end

        [X01, ord] = NormalizeAndSortByPeak(X, targetMask);
        idxCells = idxCells(ord);

        f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1400 700]);
        tiledlayout(2,1,'TileSpacing','compact','Padding','compact');

        nexttile;
        if ~isempty(X01)
            hold on;
            off = 0;
            for i = 1:size(X01,1)
                plot(timeRelSec, X01(i,:) + off, 'k', 'LineWidth', 0.7);
                off = off + 1.2;
            end
            hold off;
        end
        addMaskShading(gca, timeRelSec, maskBase, [0.75 0.85 1.0], 0.10);
        addMaskShading(gca, timeRelSec, targetMask, [0.2 0.6 1.0], 0.12);
        xline(0, '--b', 'CS on');
        title(sprintf('%s | trial %d | %s | stacked (sorted by peak in target interval)', ...
            SessionRes.SessionID, t, pop), 'Interpreter', 'none');
        ylabel('Neuron index (offset)');
        grid on;

        nexttile;
        if ~isempty(X01)
            imagesc(timeRelSec, 1:size(X01,1), X01);
            colormap('hot');
            colorbar;
            ylabel('Neuron (sorted)');
        else
            text(0.5, 0.5, 'No neurons in this population', 'HorizontalAlignment', 'center');
            axis off;
        end
        hold on;
        addMaskShading(gca, timeRelSec, maskBase, [0.75 0.85 1.0], 0.10);
        addMaskShading(gca, timeRelSec, targetMask, [0.2 0.6 1.0], 0.12);
        xline(0, '--b', 'CS on');
        hold off;
        xlabel('Time from CS onset (s)');
        title('Heatmap');

        saveas(f, fullfile(trialDir, sprintf('%s_trial%d_%s_stack_heat.fig', SessionRes.SessionID, t, pop)));
        saveas(f, fullfile(trialDir, sprintf('%s_trial%d_%s_stack_heat.png', SessionRes.SessionID, t, pop)));
        close(f);
    end

    % (b) means with spread for all populations in one figure
    f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1400 500]);
    hold on;
    C = lines(numel(popNames));

    for p = 1:numel(popNames)
        pop = popNames{p};
        idxCells = find(tr.(pop));
        X = TraceNorm(idxWin, idxCells);

        if isempty(X)
            continue;
        end
        mu = mean(X, 2, 'omitnan');
        sem = std(X, 0, 2, 'omitnan') ./ max(1, sqrt(size(X,2)));

        fill([timeRelSec; flipud(timeRelSec)], [mu-sem; flipud(mu+sem)], C(p,:), ...
            'FaceAlpha', 0.15, 'EdgeColor', 'none');
        plot(timeRelSec, mu, 'Color', C(p,:), 'LineWidth', 1.8, 'DisplayName', pop);

        for k = 1:numel(timeRelSec)
            trialRows(end+1,:) = {SessionRes.SessionID, t, timeRelSec(k), pop, mu(k), sem(k), size(X,2)}; %#ok<AGROW>
        end
    end

    xline(0, '--b', 'CS on');
    legend('Location', 'best');
    grid on;
    xlabel('Time from CS onset (s)');
    ylabel('Activity (normalized trace units)');
    title(sprintf('%s | trial %d | mean +/- SEM', SessionRes.SessionID, t), 'Interpreter', 'none');
    hold off;

    saveas(f, fullfile(trialDir, sprintf('%s_trial%d_population_mean.fig', SessionRes.SessionID, t)));
    saveas(f, fullfile(trialDir, sprintf('%s_trial%d_population_mean.png', SessionRes.SessionID, t)));
    close(f);
end

% (c) whole-session stack+heat from SessionLevel.MeanAcrossTrials populations
nFrames = size(TraceNorm,1);
tSec = ((1:nFrames)' - 1) / fps;
soundMaskAll = getFeatureMask(FeatureData, FeatureNames, 'sound');
traceMaskAll = getFeatureMask(FeatureData, FeatureNames, 'trace');
shockMaskAll = getFeatureMask(FeatureData, FeatureNames, 'shock') | getFeatureMask(FeatureData, FeatureNames, 'sound_shock');
baseMaskAll = false(nFrames,1);
for t = 1:numel(SessionRes.TrialRes)
    if isfield(SessionRes.TrialRes(t), 'BaselineMask') && ~isempty(SessionRes.TrialRes(t).BaselineMask)
        baseMaskAll = baseMaskAll | SessionRes.TrialRes(t).BaselineMask;
    end
end

for p = 1:numel(popNames)
    pop = popNames{p};
    idxCells = find(SessionRes.SessionLevel.MeanAcrossTrials.(pop));
    X = TraceNorm(:, idxCells)'; % neurons x time

    switch pop
        case {'CSTrace'}
            targetMask = soundMaskAll | traceMaskAll;
        case 'CSOnly'
            targetMask = soundMaskAll;
        case 'TraceOnly'
            targetMask = traceMaskAll;
        case 'US'
            targetMask = shockMaskAll;
    end

    [X01, ord] = NormalizeAndSortByPeak(X, targetMask);
    idxCells = idxCells(ord); %#ok<NASGU>

    f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1600 700]);
    tiledlayout(2,1,'TileSpacing','compact','Padding','compact');

    nexttile;
    if ~isempty(X01)
        hold on;
        off = 0;
        for i = 1:size(X01,1)
            plot(tSec, X01(i,:) + off, 'k', 'LineWidth', 0.7);
            off = off + 1.2;
        end
        hold off;
    end
    addMaskShading(gca, tSec, baseMaskAll, [0.75 0.85 1.0], 0.08);
    addMaskShading(gca, tSec, targetMask, [0.2 0.6 1.0], 0.10);
    xlim([tSec(1) tSec(end)]);
    title(sprintf('%s | session-level MeanAcrossTrials | %s | stacked', SessionRes.SessionID, pop), 'Interpreter', 'none');
    ylabel('Neuron index (offset)');
    grid on;

    nexttile;
    if ~isempty(X01)
        imagesc(tSec, 1:size(X01,1), X01);
        colormap('hot');
        colorbar;
        ylabel('Neuron (sorted)');
    else
        text(0.5, 0.5, 'No neurons in this population', 'HorizontalAlignment', 'center');
        axis off;
    end
    addMaskShading(gca, tSec, baseMaskAll, [0.75 0.85 1.0], 0.08);
    addMaskShading(gca, tSec, targetMask, [0.2 0.6 1.0], 0.10);
    xlim([tSec(1) tSec(end)]);
    xlabel('Session time (s)');
    title('Heatmap');

    saveas(f, fullfile(sessionLevelDir, sprintf('%s_session_%s_stack_heat.fig', SessionRes.SessionID, pop)));
    saveas(f, fullfile(sessionLevelDir, sprintf('%s_session_%s_stack_heat.png', SessionRes.SessionID, pop)));
    close(f);
end

% (d) session-level means on full session and trial-centered windows
f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1600 700]);
tiledlayout(2,1,'TileSpacing','compact','Padding','compact');
C = lines(numel(popNames));

nexttile; hold on;
for p = 1:numel(popNames)
    pop = popNames{p};
    idxCells = find(SessionRes.SessionLevel.MeanAcrossTrials.(pop));
    X = TraceNorm(:, idxCells);
    if isempty(X); continue; end
    mu = mean(X, 2, 'omitnan');
    sem = std(X, 0, 2, 'omitnan') ./ max(1, sqrt(size(X,2)));
    fill([tSec; flipud(tSec)], [mu-sem; flipud(mu+sem)], C(p,:), 'FaceAlpha', 0.15, 'EdgeColor', 'none');
    plot(tSec, mu, 'Color', C(p,:), 'LineWidth', 1.8, 'DisplayName', pop);
end
title(sprintf('%s | MeanAcrossTrials populations | full session', SessionRes.SessionID), 'Interpreter', 'none');
xlabel('Session time (s)'); ylabel('Activity'); grid on; legend('Location','best'); hold off;

nexttile; hold on;
for p = 1:numel(popNames)
    pop = popNames{p};
    [timeRel, matPop] = collectTrialAlignedMeanFixed(SessionRes, TraceNorm, pop, fps, Opts.PlotPadSec);
    if isempty(matPop); continue; end
    mu = mean(matPop, 2, 'omitnan');
    sem = std(matPop, 0, 2, 'omitnan') ./ max(1, sqrt(size(matPop,2)));
    fill([timeRel; flipud(timeRel)], [mu-sem; flipud(mu+sem)], C(p,:), 'FaceAlpha', 0.15, 'EdgeColor', 'none');
    plot(timeRel, mu, 'Color', C(p,:), 'LineWidth', 1.8, 'DisplayName', pop);
end
xline(0, '--b', 'CS on');
title('MeanAcrossTrials populations | trial-aligned baseline-sound-trace +/- 10 s');
xlabel('Time from CS onset (s)'); ylabel('Activity'); grid on; legend('Location','best'); hold off;

saveas(f, fullfile(sessionLevelDir, sprintf('%s_session_population_mean.fig', SessionRes.SessionID)));
saveas(f, fullfile(sessionLevelDir, sprintf('%s_session_population_mean.png', SessionRes.SessionID)));
close(f);

% counts + percentages
cntDir = fullfile(outRoot, SessionRes.SessionID);
if ~exist(cntDir, 'dir'); mkdir(cntDir); end
Tcnt = buildCountTable(SessionRes, popNames);
writetable(Tcnt, fullfile(cntDir, sprintf('%s_population_counts_and_percents.csv', SessionRes.SessionID)));

if ~isempty(trialRows)
    Trows = cell2table(trialRows, 'VariableNames', ...
        {'SessionID','Trial','TimeSec','Population','Mean','SEM','N'});
    writetable(Trows, fullfile(cntDir, sprintf('%s_trial_population_timeseries_for_prism.csv', SessionRes.SessionID)));
end

% (e) QA: plot all intervals per session
PlotSessionIntervalsQA(SessionRes, fps, sessionLevelDir);
end

function [X01, ord] = NormalizeAndSortByPeak(X, targetMask)
% X: neurons x time
ord = 1:size(X,1);
if isempty(X)
    X01 = X;
    return;
end

X01 = X;
for i = 1:size(X01,1)
    row = X01(i,:);
    mn = min(row);
    mx = max(row);
    if mx > mn
        X01(i,:) = (row - mn) / (mx - mn);
    else
        X01(i,:) = zeros(size(row));
    end
end

if nargin < 2 || isempty(targetMask) || ~any(targetMask)
    return;
end

idxTarget = find(targetMask(:)');
peakPos = nan(size(X01,1),1);
for i = 1:size(X01,1)
    [~, im] = max(X01(i, idxTarget));
    peakPos(i) = idxTarget(im);
end

[~, ord] = sort(peakPos, 'ascend');
X01 = X01(ord, :);
end

function mask = getFeatureMask(FeatureData, FeatureNames, nm)
idx = find(strcmp(FeatureNames, nm), 1);
if isempty(idx)
    mask = false(size(FeatureData,1),1);
else
    mask = logical(FeatureData(:, idx));
end
end

function [timeRel, matOut] = collectTrialAlignedMeanFixed(SessionRes, TraceNorm, popName, fps, padSec)
timeRel = [];
matOut = [];
pad = round(padSec * fps);
traces = {};
endSecList = [];

for t = 1:numel(SessionRes.TrialRes)
    if ~isfield(SessionRes.TrialRes(t), 'Trial') || isempty(SessionRes.TrialRes(t).Trial)
        continue;
    end
    tr = SessionRes.TrialRes(t);
    sndIdx = find(tr.SoundMask);
    trcIdx = find(tr.TraceMask);
    baseIdx = find(tr.BaselineMask);
    idxCells = find(SessionRes.SessionLevel.MeanAcrossTrials.(popName));
    if isempty(sndIdx) || isempty(idxCells)
        continue;
    end

    us2Idx = [];
    if isfield(tr, 'USMask2s')
        us2Idx = find(tr.USMask2s);
    end
    endRef = max([sndIdx(:); trcIdx(:); us2Idx(:)]);
    if isempty(endRef)
        endRef = sndIdx(end);
    end
    startRef = sndIdx(1);
    winStart = max(1, startRef - pad);
    winEnd = min(size(TraceNorm,1), endRef + pad);
    idxWin = winStart:winEnd;
    tRel = (idxWin - startRef) ./ fps;
    mu = mean(TraceNorm(idxWin, idxCells), 2, 'omitnan');
    traces{end+1} = [tRel(:), mu(:)]; %#ok<AGROW>
    endSecList(end+1) = tRel(end); %#ok<AGROW>
end

if isempty(traces)
    return;
end

timeRel = (-padSec:1/fps:max(endSecList))';
matOut = nan(numel(timeRel), numel(traces));
for i = 1:numel(traces)
    ti = traces{i}(:,1);
    yi = traces{i}(:,2);
    matOut(:, i) = interp1(ti, yi, timeRel, 'linear', nan);
end
end

function T = buildCountTable(SessionRes, popNames)
nCells = SessionRes.nCells;
modeNames = fieldnames(SessionRes.SessionLevel);
rows = {};

for i = 1:numel(modeNames)
    mode = modeNames{i};
    for p = 1:numel(popNames)
        pop = popNames{p};
        n = sum(SessionRes.SessionLevel.(mode).(pop));
        pct = 100 * n / max(1, nCells);
        rows(end+1,:) = {mode, pop, n, pct, nCells}; %#ok<AGROW>
    end
end

T = cell2table(rows, 'VariableNames', {'Mode','Population','Count','Percent','TotalNeurons'});
end

function addMaskShading(ax, tVec, mask, rgb, alphaVal)
if isempty(mask) || ~any(mask)
    return;
end

axes(ax); %#ok<LAXES>
yl = ylim(ax);
hold(ax, 'on');

mask = logical(mask(:));
tVec = tVec(:);
onsets = find(diff([0; mask]) == 1);
offsets = find(diff([mask; 0]) == -1);

for i = 1:numel(onsets)
    x0 = tVec(onsets(i));
    x1 = tVec(offsets(i));
    patch(ax, [x0 x1 x1 x0], [yl(1) yl(1) yl(2) yl(2)], rgb, ...
        'FaceAlpha', alphaVal, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    xline(ax, x0, '--', 'Color', rgb*0.7, 'HandleVisibility', 'off');
    xline(ax, x1, '--', 'Color', rgb*0.7, 'HandleVisibility', 'off');
end
uistack(findobj(ax,'Type','Line'), 'top');
end

function PlotSessionIntervalsQA(SessionRes, fps, outDir)
f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1700 900]);
tiledlayout(8,1,'TileSpacing','compact','Padding','compact');
v = [];
for i = 1:numel(SessionRes.TrialRes)
    if isfield(SessionRes.TrialRes(i), 'Trial') && ~isempty(SessionRes.TrialRes(i).Trial)
        v = i;
        break;
    end
end
if isempty(v)
    close(f);
    return;
end
nFrames = numel(SessionRes.TrialRes(v).SoundMask);
tSec = ((1:nFrames)' - 1) / fps;

for tr = 1:7
    nexttile;
    if tr > numel(SessionRes.TrialRes) || ~isfield(SessionRes.TrialRes(tr), 'Trial') || isempty(SessionRes.TrialRes(tr).Trial)
        axis off; continue;
    end
    R = SessionRes.TrialRes(tr);
    hold on;
    stairs(tSec, double(R.BaselineMask) * 1, 'Color', [0.2 0.2 0.9], 'LineWidth', 1.5);
    stairs(tSec, double(R.SoundMask) * 2, 'Color', [0.1 0.6 0.1], 'LineWidth', 1.5);
    stairs(tSec, double(R.TraceMask) * 3, 'Color', [0.9 0.5 0.1], 'LineWidth', 1.5);
    if isfield(R, 'USMask2s')
        stairs(tSec, double(R.USMask2s) * 4, 'Color', [0.8 0.1 0.1], 'LineWidth', 1.2);
    end
    stairs(tSec, double(R.USMask) * 5, '--', 'Color', [0.6 0 0], 'LineWidth', 1.5);
    hold off;
    ylim([0 5.5]); yticks(1:5); yticklabels({'baseline','sound','trace','US2s','US6s'});
    grid on;
    title(sprintf('%s | trial %d interval QA', SessionRes.SessionID, tr), 'Interpreter', 'none');
end

nexttile;
axis off;
text(0, 0.6, sprintf('Blue=baseline, Green=sound, Orange=trace, Red=US2s, dashed dark-red=US6s'), 'FontSize', 11);
text(0, 0.2, sprintf('fps=%.3f | nTrials=%d', fps, SessionRes.nTrialsAnalyzed), 'FontSize', 11);

saveas(f, fullfile(outDir, sprintf('%s_session_interval_QA.fig', SessionRes.SessionID)));
saveas(f, fullfile(outDir, sprintf('%s_session_interval_QA.png', SessionRes.SessionID)));
close(f);
end
