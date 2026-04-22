# Trace2025_pop_analysis — методика анализа популяций нейронов

Этот документ подробно описывает, **что именно делает текущий код** в папке `Trace2025_pop_analysis`, чтобы можно было верифицировать соответствие методике эксперимента.

---

## 1) Цель анализа

Для каждой сессии и каждого нейрона определить:

- `CS`-responsive
- `Trace`-responsive
- `US`-responsive
- производные популяции:
  - `CSTrace = CS ∩ Trace`
  - `CSOnly = CS \ Trace`
  - `TraceOnly = Trace \ CS`

Далее получить эти популяции:

1. на уровне **каждого trial**;
2. на уровне **сессии** (двумя способами: `MinTrials` и `MeanAcrossTrials`).

---

## 2) Входные данные и структура

Ожидаются три таблицы на сессию:

1. **Features**: `Trace_<MouseID>_<DayID>_features.csv`  
   Содержит бинарные маски событий (например `sound1..sound7`, `trace1..trace7`, `shock`, `sound_shock` и т.д.).

2. **Traces**: `Trace_<MouseID>_<DayID>_traces.csv`  
   Матрица активности нейронов (временные ряды).

3. **Timestamps**: `Trace_<MouseID>_<DayID>_timestamp.csv`  
   Используется для оценки FPS и согласования длины рядов.

Код автоматически:
- оценивает FPS;
- выравнивает длины traces/features/timestamps;
- при `BinMode='1s'` биннингует данные в 1-секундные бины;
- нормализует нейронные сигналы (`none`, `zscore`, `MADscore`).

---

## 3) Группы животных и US-колонки

Группы задаются вручную в `Run_TracePopulationAnalysis.m`:

- `delay`
- `trace`
- `distractor`

Источник US в features:

- для `delay`: колонка `sound_shock`;
- для `trace` и `distractor`: колонка `shock`.

Это зафиксировано в `AnalyzeOneSession.m`.

---

## 4) Определение окон (trial-level)

Для trial `k`:

- `soundMask = soundk`
- `traceMask = tracek`

### 4.1 Baseline

Для `delay` и `trace`:
- baseline = 20 сек перед onset `soundk`.

Для `distractor`:
- берётся кандидатное окно перед `soundk`,
- удаляются интервалы distractor и пост-интервалы после distractor,
- выбирается лучший чистый baseline (приоритет: сплошные 20 сек, иначе куски по 10 сек).

### 4.2 US окно

#### Сырой US (2 сек из таблицы)
`USMask2s` формируется из соответствующей US-колонки (`sound_shock` или `shock`) **в пределах текущего trialRegion**.

#### Расширенный US (6 сек)
`USMask` строится из onset `USMask2s` через `BuildUSMaskFromOnset(..., USWindowSec=6)`.

Итого:
- в таблице событие может быть 2 сек,
- в анализе используется окно 6 сек от onset.

### 4.3 Почему trialRegion

US-колонки (`shock`/`sound_shock`) в features обычно содержат **суммарную маску всех 7 trial**.  
Чтобы не смешивать trial между собой, код ограничивает US текущим `trialRegion` и считает `USMask2s/USMask` отдельно для каждого trial.

---

## 5) Статистика responsive-нейронов

Функция: `IsResponsive(baseVals, respVals, Opts)`.

Нейрон считается responsive, если выполняются все условия:

1. **Медиана ответа выше baseline**:  
   `median(respVals) > median(baseVals)`.

2. **Mann–Whitney U test (rank-sum), one-sided**:  
   проверяется `resp > base` (`ranksum(respVals, baseVals, 'tail','right')`),  
   p < `Opts.p_value`.

3. **Bootstrap/permutation проверка**:
   - объединённый пул `base+resp`,
   - 1000 перестановок (`Opts.NumIter`),
   - surrogate для разницы средних `mean(resp)-mean(base)`,
   - p_boot по правому хвосту,
   - p_boot < `Opts.p_value`.

Это делает критерий более строгим (и параметрическим, и перестановочным одновременно).

---

## 6) Формирование популяций

Для каждого trial:

- `CSresp`, `TRresp`, `USresp`
- `CSTrace = CSresp & TRresp`
- `CSOnly = CSresp & ~TRresp`
- `TraceOnly = TRresp & ~CSresp`

---

## 7) Session-level режимы

## 7.1 `MinTrials`

Для каждого нейрона суммируется число responsive trial; нейрон считается session-responsive, если:

`nResponsiveTrials >= Opts.MinTrialsResponsive`.

## 7.2 `MeanAcrossTrials`

Идея режима: сначала перейти от покадрового сигнала к **одному значению на trial**, а уже потом
проверять статистическую значимость между baseline и response.

### Пошагово

1. Для каждого нейрона `c` и trial `t` считаются trial-средние:
   - `baseMean(c,t) = mean(signal(baselineMask_t, c))`
   - `csMean(c,t)   = mean(signal(soundMask_t, c))`
   - `trMean(c,t)   = mean(signal(traceMask_t, c))`
   - `usMean(c,t)   = mean(signal(USMask_t, c))` (если US в trial присутствует).

2. Для оценки `CS/Trace/US` формируются векторы trial-средних:
   - CS: `baseMean(c,:)` vs `csMean(c,:)`
   - Trace: `baseMean(c,:)` vs `trMean(c,:)`
   - US: `baseMean(c,:)` vs `usMean(c,:)`.

3. На этих векторах снова применяется `IsResponsive` (та же логика, что и в trial-level):
   - проверка направления эффекта (response > baseline),
   - one-sided Mann–Whitney,
   - bootstrap/permutation критерий.

### Важное ограничение (responsive pool)

В текущей реализации `MeanAcrossTrials` считается **не по всем нейронам**.
Перед расчётом делается отбор:

- для CS-оценки берутся только нейроны, которые были CS-responsive хотя бы в одном trial;
- для Trace-оценки — только нейроны, которые были Trace-responsive хотя бы в одном trial;
- для US-оценки — только нейроны, которые были US-responsive хотя бы в одном trial.

Это intentionally делает `MeanAcrossTrials` более «консервативным» и согласованным с trial-level
детекцией (сначала trial детекция, потом session-level подтверждение на trial-средних).

### Почему так

Такой подход реализует «усреднение по trial» перед статистикой (вместо конкатенации всех фреймов)
и одновременно уменьшает вклад нейронов без признаков ответа на trial-level.

---

## 8) Что сохраняется в `SessionRes`

Ключевые поля:

- `TrialRes(trial)`:
  - маски окон (`BaselineMask`, `SoundMask`, `TraceMask`, `USMask2s`, `USMask`),
  - логические векторы популяций,
  - counts по популяциям.

- `SessionLevel.MinTrials` и `SessionLevel.MeanAcrossTrials`:
  - логические векторы популяций,
  - counts.

- `USDefinition`:
  - `SourceColumn` (`sound_shock` или `shock`),
  - `SourceMask2s_AllTrials`,
  - `ExpandedMask6s_AllTrials`.

---

## 9) Визуализация (если `Opts.MakePlots = true`)

Функция `RunPopulationVisualization.m` делает:

1. **trial-level**:
   - stacked traces + heatmap для `CSTrace/CSOnly/TraceOnly/US`,
   - сортировка нейронов по времени пика в целевом интервале,
   - mean±SEM по популяциям,
   - экспорт `.fig` + `.png`.

2. **session-level**:
   - stacked + heatmap по всей сессии (из `SessionLevel.MeanAcrossTrials`),
   - mean±SEM по всей сессии,
   - trial-aligned mean±SEM,
   - выделение целевых интервалов полупрозрачной заливкой + пунктирные границы start/end.

3. **таблицы для downstream**:
   - counts + percentages,
   - trial-level time series (CSV для Prism и аналогичных инструментов).

---

## 10) Group-level агрегация

Функция `BuildGroupLevelSummary.m` (вызывается в конце main-run, если включён plotting):

- собирает summary по `GroupType × DayID`,
- сохраняет:
  - session-wise counts/percent CSV,
  - aggregated counts/percent CSV,
  - session-wise и aggregated trial time-series CSV,
  - group/day графики (`.fig` + `.png`).

Если пересчёт сессий не нужен:
- можно запустить `BuildGroupLevelSummaryFromMatFiles(<PopAnalysisDir>)`,
- она читает уже готовые `*_PopAnalysis.mat`,
- и при наличии `*_PopCache.mat` дополнительно строит trace-dependent heatmap/кривые.

---

## 11) Важные допущения/ограничения

1. Окна зависят от качества features-таблицы (`sound1..7`, `trace1..7`, `shock/sound_shock`).
2. Для day без US (например тестовые дни без шока) `USMask` может быть пустым.
3. При несовпадении длины traces/features выполняется ресэмплинг features до длины traces.
4. При биннинге до 1 сек temporal precision событий снижается до бина.

---

## 12) Быстрый чек-лист валидации

Рекомендуется для каждой новой партии данных:

1. Проверить `SessionRes.USDefinition.SourceColumn` соответствует группе.
2. Проверить `USMask2s` и `USMask` в `TrialRes` (что они trial-specific).
3. На session heatmap убедиться, что интервалы подсвечены и границы совпадают с features.
4. Сверить counts/percentages с ручным подсчётом на 1-2 сессиях.

---

Если нужно, можно добавить в README отдельный раздел **«Математическая формализация»** (с более строгими обозначениями и формулами для статьи/методов).
