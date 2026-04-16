function fps = EstimateFPS(timeVec)
timeVec = timeVec(:);
dt = diff(timeVec);
dt = dt(~isnan(dt) & isfinite(dt) & dt > 0);

meddt = mean(dt);

% heuristic:
% if timestamps are in seconds -> fps = 1/meddt
% if in ms -> fps = 1000/meddt
if meddt > 0.5
    fps = 1000 / meddt;
else
    fps = 1 / meddt;
end
end