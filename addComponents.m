function T = addComponents(T, CompDef, nFrames, FPS, SessionName)
    for i = 1:size(CompDef,1)
        compName = CompDef{i,1};
        startSec = CompDef{i,2};
        endSec   = CompDef{i,3};

        vec = zeros(nFrames,1,'uint8');

        startFrame = floor(startSec * FPS) + 1;
        endFrameWanted = floor(endSec * FPS);

        if startFrame > nFrames
            fprintf('  %s | %s starts after end of file: startFrame=%d, rows=%d\n', ...
                SessionName, compName, startFrame, nFrames);
            T.(compName) = vec;
            continue;
        end

        endFrameActual = min(endFrameWanted, nFrames);

        if endFrameWanted > nFrames
            fprintf('  %s | %s truncated by %d frames\n', ...
                SessionName, compName, endFrameWanted - nFrames);
        end

        if endFrameActual >= startFrame
            vec(startFrame:endFrameActual) = 1;
        end

        T.(compName) = vec;
    end
end