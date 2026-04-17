function BuildGroupLevelSummary(Results, SessionCache, outRoot, Opts)

if isempty(fieldnames(Results))
    return;
end

groupDir = fullfile(outRoot, 'GroupLevel');
if ~exist(groupDir, 'dir'); mkdir(groupDir); end

popAll = {'CSTrace','CSOnly','TraceOnly','US'};
modes = {'MinTrials','MeanAcrossTrials'};
groupOrder = {'delay','trace','distractor'};
dayOrder = {'1D','2D'};

% -------------------- session rows --------------------
sessions = fieldnames(Results);
rows = {};
for i = 1:numel(sessions)
    S = Results.(sessions{i});
    if isempty(S) || ~isfield(S, 'SessionLevel'); continue; end
    for m = 1:numel(modes)
        mode = modes{m};
        for p = 1:numel(popAll)
            pop = popAll{p};
            n = sum(S.SessionLevel.(mode).(pop));
            pct = 100 * n / max(1, S.nCells);
            rows(end+1,:) = {S.MouseID, S.GroupType, S.DayID, S.SessionID, mode, pop, n, pct, S.nCells}; %#ok<AGROW>
        end
    end
end

T = cell2table(rows, 'VariableNames', ...
    {'MouseID','GroupType','DayID','SessionID','Mode','Population','Count','Percent','TotalNeurons'});
writetable(T, fullfile(groupDir, 'GroupDay_population_counts_percents_long.csv'));

% -------------------- requested 4 wide tables --------------------
for m = 1:numel(modes)
    mode = modes{m};
    Tm = T(strcmp(T.Mode, mode), :);
    Tcount = buildWideMouseTable(Tm, 'Count', groupOrder, dayOrder, popAll);
    Tperc  = buildWideMouseTable(Tm, 'Percent', groupOrder, dayOrder, popAll);
    writetable(Tcount, fullfile(groupDir, sprintf('Mouse_by_populations_%s_COUNTS.csv', mode)));
    writetable(Tperc,  fullfile(groupDir, sprintf('Mouse_by_populations_%s_PERCENT.csv', mode)));
end

% -------------------- 12 heatmaps: group x day x mode for CSOnly/TraceOnly/CSTrace --------------------
popHeat = {'CSOnly','TraceOnly','CSTrace'};
relAxis = (-30:1:50)';

for ig = 1:numel(groupOrder)
    grp = groupOrder{ig};
    for id = 1:numel(dayOrder)
        day = dayOrder{id};
        for im = 1:numel(modes)
            mode = modes{im};
            mats = cell(1, numel(popHeat));
            for p = 1:numel(popHeat)
                mats{p} = collectGroupNeuronMatrix(SessionCache, grp, day, mode, popHeat{p}, relAxis);
            end

            if all(cellfun(@isempty, mats))
                continue;
            end

            f = figure('Visible','off','Color','w','Position',[100 100 1200 900]);
            tiledlayout(3,1,'TileSpacing','compact','Padding','compact');
            pastel = [0.70 0.90 0.90; 0.95 0.80 0.90; 0.90 0.90 0.75];

            for p = 1:numel(popHeat)
                nexttile;
                X = mats{p};
                if isempty(X)
                    text(0.5,0.5,[popHeat{p} ' (n=0)'],'HorizontalAlignment','center'); axis off; continue;
                end
                Xn = normalizeRows01(X);
                [Xn,~] = sortByPeak(Xn, relAxis >= 0);
                imagesc(relAxis, 1:size(Xn,1), Xn);
                colormap(gca, turbo);
                hold on;
                patch([ -20 0 0 -20],[0 0 size(Xn,1)+1 size(Xn,1)+1], [0.85 0.90 1], 'FaceAlpha',0.12,'EdgeColor','none');
                patch([0 20 20 0],[0 0 size(Xn,1)+1 size(Xn,1)+1], pastel(p,:), 'FaceAlpha',0.10,'EdgeColor','none');
                hold off;
                xline(0,'--k'); xline(20,'--k'); xline(40,'--k');
                ylabel(sprintf('%s (n=%d)', popHeat{p}, size(Xn,1)));
                set(gca,'FontSize',12,'LineWidth',1.2);
            end
            xlabel('Time from CS onset (s)');
            sgtitle(sprintf('Group=%s | Day=%s | Mode=%s', grp, day, mode), 'Interpreter','none', 'FontSize',14, 'FontWeight','bold');

            saveas(f, fullfile(groupDir, sprintf('Heatmap_Group_%s_Day_%s_Mode_%s.fig', grp, day, mode)));
            saveas(f, fullfile(groupDir, sprintf('Heatmap_Group_%s_Day_%s_Mode_%s.png', grp, day, mode)));
            close(f);
        end
    end
end

% -------------------- dF/F paper-ready line plots + prism tables --------------------
makePaperReadyCurves(SessionCache, groupDir, relAxis);
end

function Tout = buildWideMouseTable(T, valueField, groupOrder, dayOrder, popAll)
mice = unique(T.MouseID);
ord = zeros(numel(mice),1);
for i = 1:numel(mice)
    r = T(strcmp(T.MouseID, mice{i}), :);
    if isempty(r)
        ord(i) = 99;
    else
        ord(i) = find(strcmp(groupOrder, lower(r.GroupType{1})),1);
    end
end
[~, ix] = sortrows([ord, (1:numel(mice))']);
mice = mice(ix);

vars = {'MouseID','GroupType'};
for id = 1:numel(dayOrder)
    for p = 1:numel(popAll)
        vars{end+1} = sprintf('%s_%s', dayOrder{id}, popAll{p}); %#ok<AGROW>
    end
end

data = cell(numel(mice), numel(vars));
for i = 1:numel(mice)
    m = mice{i};
    r0 = T(strcmp(T.MouseID,m),:);
    data{i,1} = m;
    if isempty(r0), data{i,2} = ''; else, data{i,2} = r0.GroupType{1}; end
    c = 3;
    for id = 1:numel(dayOrder)
        for p = 1:numel(popAll)
            rr = T(strcmp(T.MouseID,m) & strcmp(T.DayID,dayOrder{id}) & strcmp(T.Population,popAll{p}), :);
            if isempty(rr)
                data{i,c} = NaN;
            else
                data{i,c} = rr.(valueField)(1);
            end
            c = c + 1;
        end
    end
end

Tout = cell2table(data, 'VariableNames', vars);
end

function X = collectGroupNeuronMatrix(SessionCache, grp, day, mode, popName, relAxis)
X = [];
for i = 1:numel(SessionCache)
    S = SessionCache(i).SessionRes;
    if ~strcmpi(S.GroupType, grp) || ~strcmpi(S.DayID, day)
        continue;
    end
    idxCells = find(S.SessionLevel.(mode).(popName));
    if isempty(idxCells), continue; end
    Xm = extractAlignedNeurons(SessionCache(i), idxCells, relAxis);
    X = [X; Xm]; %#ok<AGROW>
end
end

function Xm = extractAlignedNeurons(C, idxCells, relAxis)
Xm = [];
Tr = C.TraceNorm;
fps = C.fps;

traces = [];
for t = 1:numel(C.SessionRes.TrialRes)
    if ~isfield(C.SessionRes.TrialRes(t),'Trial') || isempty(C.SessionRes.TrialRes(t).Trial), continue; end
    snd = find(C.SessionRes.TrialRes(t).SoundMask);
    if isempty(snd), continue; end
    csOn = snd(1);
    idx = round(csOn + relAxis * fps);
    idx(idx < 1 | idx > size(Tr,1)) = NaN;
    tmp = nan(numel(relAxis), numel(idxCells));
    ok = ~isnan(idx);
    tmp(ok,:) = Tr(idx(ok), idxCells);
    traces(:,:,end+1) = tmp; %#ok<AGROW>
end

if isempty(traces), return; end
Xm = squeeze(mean(traces, 3, 'omitnan'))';
end

function Xn = normalizeRows01(X)
Xn = X;
for i = 1:size(X,1)
    r = X(i,:);
    mn = min(r,[],'omitnan'); mx = max(r,[],'omitnan');
    if ~isnan(mn) && ~isnan(mx) && mx > mn
        Xn(i,:) = (r-mn)/(mx-mn);
    else
        Xn(i,:) = zeros(1,size(X,2));
    end
end
end

function [Xs,ord] = sortByPeak(X, mask)
idx = find(mask);
pk = nan(size(X,1),1);
for i = 1:size(X,1)
    [~,k] = max(X(i,idx));
    pk(i) = idx(k);
end
[~,ord] = sort(pk);
Xs = X(ord,:);
end

function makePaperReadyCurves(SessionCache, outDir, relAxis)
curves = {};
% training US aligned
curves{1} = struct('name','Train_US', 'day','1D', 'pops',{{'US'}}, 'alignUS',true);
curves{2} = struct('name','Train_CS_Trace', 'day','1D', 'pops',{{'CSTrace','CSOnly','TraceOnly'}}, 'alignUS',false);
curves{3} = struct('name','Test_CS_Trace', 'day','2D', 'pops',{{'CSTrace','CSOnly','TraceOnly'}}, 'alignUS',false);

colors = [0.51 0.78 0.72; 0.93 0.67 0.78; 0.74 0.79 0.92];

for ci = 1:numel(curves)
    Cfg = curves{ci};
    f = figure('Visible','off','Color','w','Position',[100 100 1200 650]);
    hold on;
    rows = {};
    for p = 1:numel(Cfg.pops)
        pop = Cfg.pops{p};
        X = [];
        for i = 1:numel(SessionCache)
            S = SessionCache(i).SessionRes;
            if ~strcmpi(S.DayID, Cfg.day), continue; end
            idxCells = find(S.SessionLevel.MeanAcrossTrials.(pop));
            if isempty(idxCells), continue; end
            Xm = extractAlignedNeurons(SessionCache(i), idxCells, relAxis);
            X = [X; Xm]; %#ok<AGROW>
        end
        if isempty(X), continue; end
        mu = mean(X,1,'omitnan')';
        sem = std(X,0,1,'omitnan')' ./ max(1,sqrt(size(X,1)));
        cc = colors(min(p,size(colors,1)),:);
        fill([relAxis; flipud(relAxis)], [mu-sem; flipud(mu+sem)], cc, 'FaceAlpha',0.20, 'EdgeColor','none');
        plot(relAxis, mu, 'LineWidth', 2.8, 'Color', cc, 'DisplayName', pop);
        for k = 1:numel(relAxis)
            rows(end+1,:) = {Cfg.name, pop, relAxis(k), mu(k), sem(k), size(X,1)}; %#ok<AGROW>
        end
    end
    xline(0,'--k','CS on');
    xline(20,'--k','sound off');
    xline(40,'--k','trace off');
    xlabel('Time from CS onset (s)','FontSize',16);
    ylabel('dF/F (a.u.)','FontSize',16);
    set(gca,'FontSize',14,'LineWidth',1.4);
    grid on;
    legend('Location','best','FontSize',13);
    title(strrep(Cfg.name,'_',' '),'FontSize',18,'FontWeight','bold');
    saveas(f, fullfile(outDir, [Cfg.name '_paper_ready.fig']));
    saveas(f, fullfile(outDir, [Cfg.name '_paper_ready.png']));
    close(f);

    if ~isempty(rows)
        T = cell2table(rows, 'VariableNames', {'Curve','Population','TimeSec','Mean','SEM','N'});
        writetable(T, fullfile(outDir, [Cfg.name '_for_prism.csv']));
    end
end
end
