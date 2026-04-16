function [line] = MyFilt1(line,wind,value)
% Removes short runs of VALUE shorter than WIND from a binary line.
% line  - binary vector
% wind  - minimum allowed run length
% value - value to filter out if run is too short (0 or 1)

    antivalue = double(~value);
    frames = length(line);

    count = double(line(1) == value);

    for i = 2:frames
        if line(i) == value
            count = count + 1;
        end

        % End of a run of VALUE
        if (line(i) == antivalue) && (line(i-1) == value)
            if count < wind && (i - count ~= 1)
                line(i-count:i-1) = antivalue;
            end
            count = 0;
        end
    end

    % Process run reaching the end of the vector
    if line(frames) == value
        if count < wind && (frames - count + 1 ~= 1)
            line(frames-count+1:frames) = antivalue;
        end
    end
end