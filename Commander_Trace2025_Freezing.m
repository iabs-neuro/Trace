%% Components in seconds

Components_1D_Delay =       '90 20 2 18 2 90 20 2 18 2 90 20 2 18 2 90 20 2 18 2 90 20 2 18 2 90 20 2 18 2 90 20 2 18 2 90';
Components_1D_Trace =       '90 20 2 18 2 90 20 2 18 2 90 20 2 18 2 90 20 2 18 2 90 20 2 18 2 90 20 2 18 2 90 20 2 18 2 90';
Components_1D_Distractor =  '90 20 2 18 2 90 20 2 18 2 90 20 2 18 2 90 20 2 18 2 90 20 2 18 2 90 20 2 18 2 90 20 2 18 2 90';
Components_2D_Sound = '90 20 20 60 20 20 110 20 20 85 20 20 100 20 20 70 20 20 65 20 20 105';
Components_3D_Distract = '90 3 15 3 30 3 22 3 20 3 25 3 27 3 17 3 15 3 30 3 24 3 18 3 27 3 24 3 21 3 18 3 15 3 30 3 23 3 16 3 29';
Components_4D_Context = '60 60 60 60 60';

VideoPath = 'e:\Projects\Trace\BehaviorData\1_Raw\';
OutPath = 'e:\Projects\Trace\BehaviorData\4_Freezing\';

Delay  = {'J02' 'J07' 'J13' 'J19' 'J26' 'J27' 'J29' 'J52' 'J57' 'J58'};
Trace = {'J01' 'J03' 'J05' 'J10' 'J18' 'J20' 'J24' 'J53'};
Distractor = {'J06' 'J12' 'J14' 'J17' 'J25' 'J54' 'J55' 'J59' 'J61'};
FileNames_all = {'J02' 'J07' 'J13' 'J19' 'J26' 'J27' 'J29' 'J52' 'J57' 'J58' 'J01' 'J03' 'J05' 'J10' 'J18' 'J20' 'J24' 'J53' 'J06' 'J12' 'J14' 'J17' 'J25' 'J54' 'J55' 'J59' 'J61'};

%% FREEZING CALCULATION

% 1D Training Delay
FileNames = Delay;
Components = Components_1D_Delay;

nComponents = numel(str2num(Components));
PctComponentTimeFreezing1D_Delay = zeros(length(FileNames), nComponents);

for file = 1:length(FileNames)
    FileName = sprintf('%s_trace_1D.wmv',FileNames{file});    
    display(FileName);
    [PctComponentTimeFreezing] = VideoFreezingTrace25(0,VideoPath,FileName,3,Components,Components,13,5,18,15,144);
    PctComponentTimeFreezing1D_Delay(file,1:nComponents) = PctComponentTimeFreezing(2,:);
end

% 1D Training Trace
FileNames = Trace;
Components = Components_1D_Trace;
nComponents = numel(str2num(Components));
PctComponentTimeFreezing1D_Trace = zeros(length(FileNames),nComponents);
for file = 1:length(FileNames)
    FileName = sprintf('%s_trace_1D.wmv',FileNames{file});
    display(FileName);
    [PctComponentTimeFreezing] = VideoFreezingTrace25(0,VideoPath,FileName,3,Components,Components,13,5,18,15,144);
    PctComponentTimeFreezing1D_Trace(file,1:nComponents) = PctComponentTimeFreezing(2,:);
end

% 1D Training Distractor
FileNames = Distractor;
Components = Components_1D_Distractor;
nComponents = numel(str2num(Components));
PctComponentTimeFreezing1D_Distractor = zeros(length(FileNames),nComponents);
for file = 1:length(FileNames)
    FileName = sprintf('%s_trace_1D.wmv',FileNames{file});
    display(FileName);
    [PctComponentTimeFreezing] = VideoFreezingTrace25(0,VideoPath,FileName,3,Components,Components,13,5,18,15,144);
    PctComponentTimeFreezing1D_Distractor(file,1:nComponents) = PctComponentTimeFreezing(2,:);
end

%% 2D Sound
FileNames = FileNames_all;
Components = Components_2D_Sound;
nComponents = numel(str2num(Components));
PctComponentTimeFreezing2D_Sound = zeros(length(FileNames),nComponents);
for file = 1:length(FileNames)
    FileName = sprintf('%s_trace_2D.wmv',FileNames{file});
    display(FileName);
    [PctComponentTimeFreezing] = VideoFreezingTrace25(0,VideoPath,FileName,3,Components,Components,13,5,18,15,144);
    PctComponentTimeFreezing2D_Sound(file,1:nComponents) = PctComponentTimeFreezing(2,:);
end

% 3D Distract
FileNames = FileNames_all;
Components = Components_3D_Distract;
nComponents = numel(str2num(Components));
PctComponentTimeFreezing3D_Distract = zeros(length(FileNames),nComponents);
for file = 1:length(FileNames)
    FileName = sprintf('%s_trace_3D.wmv',FileNames{file});
    display(FileName);
    [PctComponentTimeFreezing] = VideoFreezingTrace25(0,VideoPath,FileName,3,Components,Components,13,5,18,15,144);
    PctComponentTimeFreezing3D_Distract(file,1:nComponents) = PctComponentTimeFreezing(2,:);
end

% 4D Context
FileNames = FileNames_all;
Components = Components_4D_Context;
nComponents = numel(str2num(Components));
PctComponentTimeFreezing4D_Context = zeros(length(FileNames),nComponents);
for file = 1:length(FileNames)
    FileName = sprintf('%s_trace_4D.wmv',FileNames{file});
    display(FileName);
    [PctComponentTimeFreezing] = VideoFreezingTrace25(0,VideoPath,FileName,3,Components,Components,13,5,18,15,144);
    PctComponentTimeFreezing4D_Context(file,1:nComponents) = PctComponentTimeFreezing(2,:);
end