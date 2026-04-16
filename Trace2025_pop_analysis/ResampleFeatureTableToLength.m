function Tout = ResampleFeatureTableToLength(Tin, nTarget)
% Resample feature table to target number of rows by index mapping.
% Good for binary 0/1 feature tables.
%
% Start and end stay aligned.
% Extra rows are dropped uniformly; if rows are fewer, some rows repeat.

    nSource = height(Tin);

    if nSource == nTarget
        Tout = Tin;
        return;
    end

    idx = round(linspace(1, nSource, nTarget));
    idx(idx < 1) = 1;
    idx(idx > nSource) = nSource;

    Tout = Tin(idx, :);
end