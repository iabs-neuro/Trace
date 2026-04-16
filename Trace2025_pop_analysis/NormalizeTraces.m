function Xn = NormalizeTraces(X, normWay)

Xn = zeros(size(X));

switch lower(normWay)
    case 'none'
        Xn = X;

    case 'zscore'
        for c = 1:size(X,2)
            Xn(:,c) = zscore(X(:,c));
        end

    case 'madscore'
        for c = 1:size(X,2)
            medv = median(X(:,c), 'omitnan');
            madv = mad(X(:,c), 1);
            if madv == 0 || isnan(madv)
                Xn(:,c) = X(:,c) - medv;
            else
                Xn(:,c) = (X(:,c) - medv) ./ madv;
            end
        end

    otherwise
        error('Unknown NormWay: %s', normWay);
end
end