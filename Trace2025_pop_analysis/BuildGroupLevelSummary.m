function BuildGroupLevelSummary(Results, outRoot)

if isempty(fieldnames(Results))
    return;
end

groupDir = fullfile(outRoot, 'GroupLevel');
if ~exist(groupDir, 'dir')
    mkdir(groupDir);
end

sessions = fieldnames(Results);
countRows = {};
tsRows = {};

for i = 1:numel(sessions)
    S = Results.(sessions{i});
    if isempty(S) || ~isfield(S, 'SessionLevel')
        continue;
    end

    modeNames = fieldnames(S.SessionLevel);
    popNames = {'CSTrace','CSOnly','TraceOnly','US'};

    for m = 1:numel(modeNames)
        mode = modeNames{m};
        for p = 1:numel(popNames)
            pop = popNames{p};
            n = sum(S.SessionLevel.(mode).(pop));
            pct = 100 * n / max(1, S.nCells);
            countRows(end+1,:) = {S.GroupType, S.DayID, S.SessionID, mode, pop, n, pct, S.nCells}; %#ok<AGROW>
        end
    end

    tsFile = fullfile(outRoot, S.SessionID, sprintf('%s_trial_population_timeseries_for_prism.csv', S.SessionID));
    if isfile(tsFile)
        T = readtable(tsFile);
        if ~isempty(T)
            g = repmat({S.GroupType}, height(T), 1);
            d = repmat({S.DayID}, height(T), 1);
            sid = repmat({S.SessionID}, height(T), 1);
            T2 = table(g, d, sid, T.Trial, T.TimeSec, T.Population, T.Mean, T.SEM, T.N, ...
                'VariableNames', {'GroupType','DayID','SessionID','Trial','TimeSec','Population','Mean','SEM','N'});
            tsRows{end+1} = T2; %#ok<AGROW>
        end
    end
end

if isempty(countRows)
    return;
end

Tcount = cell2table(countRows, 'VariableNames', ...
    {'GroupType','DayID','SessionID','Mode','Population','Count','Percent','TotalNeurons'});
writetable(Tcount, fullfile(groupDir, 'GroupDay_population_counts_percents.csv'));

if ~isempty(tsRows)
    Tall = vertcat(tsRows{:});
    writetable(Tall, fullfile(groupDir, 'GroupDay_trial_population_timeseries.csv'));
else
    Tall = table();
end

% aggregated table and figure per group/day/mode/pop
G = groupsummary(Tcount, {'GroupType','DayID','Mode','Population'}, {'mean','std'}, {'Count','Percent'});
writetable(G, fullfile(groupDir, 'GroupDay_population_counts_percents_aggregated.csv'));

% simple bar plots for aggregated percentages
uGroup = unique(Tcount.GroupType);
uDay = unique(Tcount.DayID);
uMode = unique(Tcount.Mode);
uPop = {'CSTrace','CSOnly','TraceOnly','US'};

for ig = 1:numel(uGroup)
    for id = 1:numel(uDay)
        for im = 1:numel(uMode)
            sel = strcmp(G.GroupType, uGroup{ig}) & strcmp(G.DayID, uDay{id}) & strcmp(G.Mode, uMode{im});
            if ~any(sel); continue; end

            f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 900 500]);
            vals = nan(1, numel(uPop));
            errs = nan(1, numel(uPop));
            for p = 1:numel(uPop)
                s2 = sel & strcmp(G.Population, uPop{p});
                if any(s2)
                    vals(p) = G.mean_Percent(s2);
                    errs(p) = G.std_Percent(s2);
                end
            end
            bh = bar(vals, 'FaceColor', [0.2 0.5 0.8]); %#ok<NASGU>
            hold on;
            errorbar(1:numel(uPop), vals, errs, 'k.', 'LineWidth', 1.5);
            hold off;
            set(gca, 'XTick', 1:numel(uPop), 'XTickLabel', uPop);
            ylabel('Percent of neurons');
            grid on;
            title(sprintf('Group=%s | Day=%s | Mode=%s', uGroup{ig}, uDay{id}, uMode{im}), 'Interpreter', 'none');
            saveas(f, fullfile(groupDir, sprintf('Group_%s_Day_%s_Mode_%s_percent_bar.fig', uGroup{ig}, uDay{id}, uMode{im})));
            saveas(f, fullfile(groupDir, sprintf('Group_%s_Day_%s_Mode_%s_percent_bar.png', uGroup{ig}, uDay{id}, uMode{im})));
            close(f);
        end
    end
end

% time-series group/day averages
if ~isempty(Tall)
    Gts = groupsummary(Tall, {'GroupType','DayID','Trial','TimeSec','Population'}, 'mean', 'Mean');
    writetable(Gts, fullfile(groupDir, 'GroupDay_trial_population_timeseries_aggregated.csv'));

    for ig = 1:numel(uGroup)
        for id = 1:numel(uDay)
            for tr = 1:7
                sel = strcmp(Gts.GroupType, uGroup{ig}) & strcmp(Gts.DayID, uDay{id}) & Gts.Trial == tr;
                if ~any(sel); continue; end
                f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 900 500]);
                hold on;
                C = lines(numel(uPop));
                for p = 1:numel(uPop)
                    s2 = sel & strcmp(Gts.Population, uPop{p});
                    if ~any(s2); continue; end
                    plot(Gts.TimeSec(s2), Gts.mean_Mean(s2), 'LineWidth', 2, 'Color', C(p,:), 'DisplayName', uPop{p});
                end
                xline(0, '--b', 'CS on');
                xlabel('Time from CS onset (s)');
                ylabel('Mean activity');
                grid on;
                legend('Location', 'best');
                title(sprintf('Group=%s | Day=%s | Trial=%d', uGroup{ig}, uDay{id}, tr), 'Interpreter', 'none');
                hold off;
                saveas(f, fullfile(groupDir, sprintf('Group_%s_Day_%s_Trial_%d_mean.fig', uGroup{ig}, uDay{id}, tr)));
                saveas(f, fullfile(groupDir, sprintf('Group_%s_Day_%s_Trial_%d_mean.png', uGroup{ig}, uDay{id}, tr)));
                close(f);
            end
        end
    end
end
end
