function vec = unionByPrefix(T, prefix)
    vars = T.Properties.VariableNames;
    mask = startsWith(vars, prefix);
    mask = mask & ~strcmp(vars, prefix);

    if any(mask)
        X = T{:, mask};
        vec = uint8(any(X > 0, 2));
    else
        vec = zeros(height(T),1,'uint8');
    end
end