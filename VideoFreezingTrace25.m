function [PctComponentTimeFreezing] = VideoFreezingTrace25(PlotVideo,path,filename,Both,CompUp,CompDown,noiZelvl,MinLengthFreez,MotThres,FreezDuratV,Line)
% VideoFreezingFuncG
% Calculates percent of freezing time in video components.
%
% INPUTS are preserved exactly as in original function.
% OUTPUT:
%   PctComponentTimeFreezing - percent freezing in each component
%
% Notes:
%   Both = 1  -> whole cage
%   Both = 2  -> up side
%   Both = 3  -> down side
%   Both = 4? -> both sides (legacy logic preserved through up/down selection)
%
% Line = 0 -> select dividing line manually
% Line > 0 -> use horizontal dividing line at this height

    if nargin < 11
        [filename, path] = uigetfile('*.wmv','Select wmv file','e:\Projects\Trace\BehaviorData\1_Raw\');
        Both = listdlg('PromptString','Select the way of mouse location ', ...
                       'ListString', {'whole cage', 'up side', 'down side', 'both side'}, ...
                       'ListSize', [170 60]);

        prompt = {'Duration of components for up sector, s', ...
                  'Duration of components for down sector, s', ...
                  'Noise level (0-255)', ...
                  'Minimum freeze length / filter window', ...
                  'Motion threshold, px', ...
                  'Minimum freeze duration (frames, for 30 fps)', ...
                  'Dividing line height (0 to select manually)'};

        default_data = {'300','300','13','5','18','15','144'};
        options.Resize = 'on';
        dlg_data = inputdlg(prompt, 'Parameters', 1, default_data, options);

        DuratCompUp   = str2num(dlg_data{1}); %#ok<ST2NM>
        DuratCompDown = str2num(dlg_data{2}); %#ok<ST2NM>
        noiZelvl      = str2num(dlg_data{3}); %#ok<ST2NM>
        MinLengthFreez = str2num(dlg_data{4}); %#ok<ST2NM>
        MotThres      = str2num(dlg_data{5}); %#ok<ST2NM>
        FreezDuratV   = str2num(dlg_data{6}); %#ok<ST2NM>
        Line          = str2num(dlg_data{7}); %#ok<ST2NM>

        PlotVideo = 1;
    else
        DuratCompUp   = str2num(CompUp);   %#ok<ST2NM>
        DuratCompDown = str2num(CompDown); %#ok<ST2NM>
    end

    MaxLengthFreez = FreezDuratV;

    disp('Loading video...');
    save(fullfile(path, sprintf('%s_WorkSpace_%d_%d_%d_%d.mat', ...
        filename(1:end-4), noiZelvl, MinLengthFreez, MotThres, FreezDuratV)));
    videoFile = fullfile(path, filename);
    readerobj = VideoReader(videoFile);

    % Read full video once
    vidFrames = read(readerobj);

    % Basic video parameters
    numFrames = size(vidFrames, 4);
    FrameRate = readerobj.FrameRate;
    Height    = size(vidFrames, 1);
    Width     = size(vidFrames, 2);

    % Use only first channel, as in original code
    grayFrames = squeeze(vidFrames(:,:,1,:));   % Height x Width x numFrames
    grayFrames = uint8(grayFrames);

    %% Dividing line between up/down sectors
    if Both ~= 1
        if Line == 0
            IM = grayFrames(:,:,min(100, numFrames));
            figure;
            imshow(IM);
            title('Select points for dividing line');
            hold on;

            prompt = {'Polynomial degree for dividing line (e.g. 1 for straight line)'};
            default_data = {'1'};
            options.Resize = 'on';
            dlg_data = inputdlg(prompt, 'Parameters', 1, default_data, options);
            degree = str2num(dlg_data{1}); %#ok<ST2NM>

            [x, y] = ginput;
            p = polyfit(x, y, degree);
            x1 = 1:Width;
            y1 = polyval(p, x1);

            plot(x, y, 'ro');
            plot(x1, y1, 'g-', 'LineWidth', 2);
            hold off;
        else
            y1 = ones(1, Width) * Line;
        end

        % Clamp line to image bounds
        y1 = round(y1);
        y1(y1 < 1) = 1;
        y1(y1 > Height) = Height;
    end

    %% Component borders in frames
    NumberComp = [length(DuratCompUp), length(DuratCompDown)];
    numFramesVcomp = zeros(2, max(NumberComp) + 1);

    for i = 1:NumberComp(1)-1
        numFramesVcomp(1, i+1) = numFramesVcomp(1, i) + DuratCompUp(i) * FrameRate;
    end

    for i = 1:NumberComp(2)-1
        numFramesVcomp(2, i+1) = numFramesVcomp(2, i) + DuratCompDown(i) * FrameRate;
    end

    numFramesVcomp(1, NumberComp(1)+1) = numFrames - 1;
    numFramesVcomp(2, NumberComp(2)+1) = numFrames - 1;

    %% Masks
    upMask = true(Height, Width);
    downMask = true(Height, Width);

    if Both ~= 1
        upMask = false(Height, Width);
        for col = 1:Width
            upMask(1:y1(col)-1, col) = true;
        end
        downMask = ~upMask;
    end

    % Which sectors to process
    up = 1;
    down = 2;

    if Both == 1 || Both == 2
        up = 1;
        down = 1;
    elseif Both == 3
        up = 2;
        down = 2;
    end

    numFramesV = numFrames - 1;

    % Preallocate
    MotInd = zeros(2, numFramesV);
    MotIndThres = zeros(2, numFramesV);
    MotIndThresFreez = zeros(2, numFrames);
    PctComponentTimeFreezing = zeros(2, max(NumberComp));

    %% Main loop by sector
    for m = up:down
        if m == 1
            Mask = upMask;
            sectorName = 'up';
        else
            Mask = downMask;
            sectorName = 'down';
        end

        % Motion index: count changed pixels between adjacent frames
        for i = 1:numFramesV
            dat0 = grayFrames(:,:,i);
            dat1 = grayFrames(:,:,i+1);

            diffFrame = abs(double(dat0) - double(dat1));
            diffFrame(~Mask) = 0;

            MotInd(m,i) = nnz(diffFrame > noiZelvl);
        end

        % Binary motion threshold -> candidate freezing
        MotIndThres(m,:) = MotInd(m,:) < MotThres;

        %% Refine freezing sequence
        freez = MotIndThres(m,:);

        % Keep / merge bouts using legacy helper functions
        freez_filt0 = MyFilt1(freez, MinLengthFreez, 0);
        freez_filt1 = MyFilt1(freez_filt0, MaxLengthFreez, 1);

        [freez_ref, ~, ~, ~, ~, ~] = RefineLine(freez_filt1, 0, 0);

        %% Plot raw/refined freeze line
        h = figure('Visible', 'off');
        title(sprintf('Raw and refined freezing line (%s)', sectorName), 'FontSize', 15);
        xlabel('Frame', 'FontSize', 15);
        ylabel('Freezing / Motion index', 'FontSize', 15);
        hold on;
        plot(1:numFramesV, MotInd(m,:), 'b');
        plot(1:numFramesV, freez .* MotThres, 'g', 'LineWidth', 2);
        plot(1:numFramesV, freez_ref .* (MotThres + 3), 'c', 'LineWidth', 2);
        legend('Motion index','Freeze raw','Freeze refined');
        hold off;

        saveas(h, fullfile(path, sprintf('%s_FreezRawVsRef_%s_%d_%d_%d_%d.png', ...
            filename(1:end-4), sectorName, noiZelvl, MinLengthFreez, MotThres, FreezDuratV)));
        saveas(h, fullfile(path, sprintf('%s_FreezRawVsRef_%s_%d_%d_%d_%d.fig', ...
            filename(1:end-4), sectorName, noiZelvl, MinLengthFreez, MotThres, FreezDuratV)));
        close(h);

       %% Optional output video
if PlotVideo
    outVideoName = fullfile(path, sprintf('%s_freezing_%s_%d_%d_%d_%d.mp4', ...
        filename(1:end-4), sectorName, noiZelvl, MinLengthFreez, MotThres, FreezDuratV));
    v = VideoWriter(outVideoName, 'MPEG-4');
    v.FrameRate = FrameRate;
    open(v);

    BlackFrame = zeros(Height, Width, 3, 'uint8');

    if Both == 1
        StartRow = 1;
    else
        StartRow = round(mean(y1));
        StartRow = max(1, min(StartRow, Height));
    end
    CropRows = StartRow:Height;

    h = waitbar(1/numFramesV, sprintf('Plotting video, frame %d of %d', 0, numFramesV));
    for k = 1:numFramesV
        if ~mod(k,100)
            h = waitbar(k/numFramesV, h, sprintf('Plotting video, frame %d of %d', k, numFramesV));
        end

        dat0 = grayFrames(:,:,k);
        dat1 = grayFrames(:,:,k+1);

        diffFrame = abs(double(dat0) - double(dat1));
        diffFrame(~Mask) = 0;
        diffFrame = uint8(diffFrame > noiZelvl) * 255;

        MovFrame = repmat(diffFrame, [1 1 3]);
        RealFrame = vidFrames(:,:,:,k);

        if freez_ref(k)
            IM = [RealFrame(CropRows,:,:); ...
                  RealFrame(CropRows,:,:); ...
                  MovFrame(CropRows,:,:)];
        else
            IM = [RealFrame(CropRows,:,:); ...
                  BlackFrame(CropRows,:,:); ...
                  MovFrame(CropRows,:,:)];
        end

        writeVideo(v, IM);
    end

    close(v);
    delete(h);
end

        %% Final freeze bouts with minimum duration
        count = 0;
        for i = 1:numFramesV
            if freez_ref(i) == 1
                count = count + 1;
            end

            isEndBout = (freez_ref(i) == 0) || ((freez_ref(i) == 1) && (i == numFramesV));

            if isEndBout && (count ~= 0)
                if count >= FreezDuratV - 1
                    if i ~= numFramesV
                        idx1 = i - count;
                        idx2 = i;
                    else
                        idx1 = i - count + 1;
                        idx2 = i + 1;
                    end
                    idx1 = max(1, idx1);
                    idx2 = min(numFrames, idx2);
                    MotIndThresFreez(m, idx1:idx2) = 1;
                end
                count = 0;
            end
        end

        %% Divide into components
        for l = 1:NumberComp(m)
            idxStart = round(numFramesVcomp(m,l) + 1);
            idxEnd   = round(numFramesVcomp(m,l+1));

            idxStart = max(1, idxStart);
            idxEnd   = min(numFrames, idxEnd);

            if idxEnd >= idxStart
                summa = sum(MotIndThresFreez(m, idxStart:idxEnd));
                PctComponentTimeFreezing(m,l) = summa / (idxEnd - idxStart + 1) * 100;
            else
                PctComponentTimeFreezing(m,l) = NaN;
            end
        end
    end

    %% Save outputs
    % Save only processed sector if single-sector mode was used
    if down == 1
        csvwrite(fullfile(path, sprintf('%s_Freezing_%d_%d_%d_%d.csv', ...
            filename(1:end-4), noiZelvl, MinLengthFreez, MotThres, FreezDuratV)), ...
            MotIndThresFreez(1,:)');
        csvwrite(fullfile(path, sprintf('%s_MotionIndex_%d_%d_%d_%d.csv', ...
            filename(1:end-4), noiZelvl, MinLengthFreez, MotThres, FreezDuratV)), ...
            MotInd(1,:)');
    else
        csvwrite(fullfile(path, sprintf('%s_Freezing_%d_%d_%d_%d.csv', ...
            filename(1:end-4), noiZelvl, MinLengthFreez, MotThres, FreezDuratV)), ...
            MotIndThresFreez(2,:)');
        csvwrite(fullfile(path, sprintf('%s_MotionIndex_%d_%d_%d_%d.csv', ...
            filename(1:end-4), noiZelvl, MinLengthFreez, MotThres, FreezDuratV)), ...
            MotInd(2,:)');
    end

%     save(fullfile(path, sprintf('%s_WorkSpace_%d_%d_%d_%d.mat', ...
%         filename(1:end-4), noiZelvl, MinLengthFreez, MotThres, FreezDuratV)));
end