clear; clc;

%% Paths
InPath  = 'e:\Projects\Trace\BehaviorData\5_Freezing\';
OutPath = 'e:\Projects\Trace\BehaviorData\6_Stimulus\';

if ~exist(OutPath, 'dir')
    mkdir(OutPath);
end

FPS = 30;

%% Groups
DelayGroup      = {'J02','J07','J13','J19','J26','J27','J29','J52','J57','J58'};
TraceGroup      = {'J01','J03','J05','J10','J18','J20','J24','J53'};
DistractorGroup = {'J06','J12','J14','J17','J25','J54','J55','J59','J61'};

%% Component definitions

% ---------- 1D common ----------
Comp1D = {
    'ITI0',    0,   90;
    'sound1',  90,  110;
    'trace1',  112, 130;
    'ITI1',    132, 222;
    'sound2',  222, 242;
    'trace2',  244, 262;
    'ITI2',    264, 354;
    'sound3',  354, 374;
    'trace3',  376, 394;
    'ITI3',    396, 486;
    'sound4',  486, 506;
    'trace4',  508, 526;
    'ITI4',    528, 618;
    'sound5',  618, 638;
    'trace5',  640, 658;
    'ITI5',    660, 750;
    'sound6',  750, 770;
    'trace6',  772, 790;
    'ITI6',    792, 882;
    'sound7',  882, 902;
    'trace7',  904, 922;
    'ITI7',    924, 1014;
};

% ---------- 1D delay additional ----------
Comp1D_SoundShock = {
    'sound_shock1', 110, 112;
    'sound_shock2', 242, 244;
    'sound_shock3', 374, 376;
    'sound_shock4', 506, 508;
    'sound_shock5', 638, 640;
    'sound_shock6', 770, 772;
    'sound_shock7', 902, 904;
};

% ---------- 1D trace+distr additional ----------
Comp1D_Shock = {
    'shock1', 130, 132;
    'shock2', 262, 264;
    'shock3', 394, 396;
    'shock4', 526, 528;
    'shock5', 658, 660;
    'shock6', 790, 792;
    'shock7', 922, 924;
};

% ---------- 1D distractor only ----------
Comp1D_Distr = {
    'distr1',   9,  12;
    'distr2',  42,  45;
    'distr3',  61,  64;
    'distr4',  74,  77;
    'distr5',  99, 102;
    'distr6', 119, 122;
    'distr7', 141, 144;
    'distr8', 174, 177;
    'distr9', 193, 196;
    'distr10',206, 209;
    'distr11',231, 234;
    'distr12',251, 254;
    'distr13',273, 276;
    'distr14',306, 309;
    'distr15',325, 328;
    'distr16',338, 341;
    'distr17',363, 366;
    'distr18',383, 386;
    'distr19',405, 408;
    'distr20',438, 441;
    'distr21',457, 460;
    'distr22',470, 473;
    'distr23',495, 498;
    'distr24',515, 518;
    'distr25',537, 540;
    'distr26',570, 573;
    'distr27',589, 592;
    'distr28',602, 605;
    'distr29',627, 630;
    'distr30',647, 650;
    'distr31',669, 672;
    'distr32',702, 705;
    'distr33',721, 724;
    'distr34',734, 737;
    'distr35',759, 762;
    'distr36',779, 782;
    'distr37',801, 804;
    'distr38',834, 837;
    'distr39',853, 856;
    'distr40',866, 869;
    'distr41',891, 894;
    'distr42',911, 914;
    'distr43',933, 936;
    'distr44',966, 969;
    'distr45',985, 988;
    'distr46',998, 1001;
};

% ---------- 2D ----------
Comp2D = {
    'ITI0',   0,   90;
    'sound1', 90, 110;
    'trace1', 110,130;
    'ITI1',   130,190;
    'sound2', 190,210;
    'trace2', 210,230;
    'ITI2',   230,340;
    'sound3', 340,360;
    'trace3', 360,380;
    'ITI3',   380,465;
    'sound4', 465,485;
    'trace4', 485,505;
    'ITI4',   505,605;
    'sound5', 605,625;
    'trace5', 625,645;
    'ITI5',   645,715;
    'sound6', 715,735;
    'trace6', 735,755;
    'ITI6',   755,820;
    'sound7', 820,840;
    'trace7', 840,860;
    'ITI7',   860,965;
};

% ---------- 3D ----------
Comp3D = {
    'ITI0',   0,   90;
    'distr1', 90,  93;
    'ITI1',   93, 108;
    'distr2',108, 111;
    'ITI2',  111, 141;
    'distr3',141, 144;
    'ITI3',  144, 166;
    'distr4',166, 169;
    'ITI4',  169, 189;
    'distr5',189, 192;
    'ITI5',  192, 217;
    'distr6',217, 220;
    'ITI6',  220, 247;
    'distr7',247, 250;
    'ITI7',  250, 267;
    'distr8',267, 270;
    'ITI8',  270, 285;
    'distr9',285, 288;
    'ITI9',  288, 318;
    'distr10',318,321;
    'ITI10', 321, 345;
    'distr11',345,348;
    'ITI11', 348, 366;
    'distr12',366,369;
    'ITI12', 369, 396;
    'distr13',396,399;
    'ITI13', 399, 423;
    'distr14',423,426;
    'ITI14', 426, 447;
    'distr15',447,450;
    'ITI15', 450, 468;
    'distr16',468,471;
    'ITI16', 471, 486;
    'distr17',486,489;
    'ITI17', 489, 519;
    'distr18',519,522;
    'ITI18', 522, 545;
    'distr19',545,548;
    'ITI19', 548, 564;
    'distr20',564,567;
    'ITI20', 567, 596;
};

% ---------- 4D ----------
Comp4D = {
    'min1', 0,   60;
    'min2', 60, 120;
    'min3',120, 180;
    'min4',180, 240;
    'min5',240, 300;
};

%% Find input files
files = dir(fullfile(InPath, '*_Freezing_*.csv'));
fprintf('Found %d freezing files\n', numel(files));

for f = 1:numel(files)
    inFile = files(f).name;
    inFull = fullfile(InPath, inFile);

    Tref = readtable(inFull);
    nFrames = height(Tref);

    tok = regexp(inFile, '^(J\d+)_trace_(\dD)_Freezing_.*\.csv$', 'tokens', 'once');
    if isempty(tok)
        fprintf('Skip (name not matched): %s\n', inFile);
        continue;
    end

    MouseID = tok{1};
    DayID   = tok{2};
    SessionName = sprintf('%s_trace_%s', MouseID, DayID);

    fprintf('\nProcessing %s | rows=%d\n', SessionName, nFrames);

    switch DayID
        case '1D'
            Tbase = table();

            % separate base components
            Tbase = addComponents(Tbase, Comp1D, nFrames, FPS, SessionName);

            % global unions
            SoundVec = unionByPrefix(Tbase, 'sound');
            TraceVec = unionByPrefix(Tbase, 'trace');
            ITIVec   = unionByPrefix(Tbase, 'ITI');

            Tst = table();
            for k = 1:7
                sName = sprintf('sound%d', k);
                tName = sprintf('trace%d', k);
                stName = sprintf('sound_trace_%d', k);
                Tst.(stName) = uint8(Tbase.(sName) | Tbase.(tName));
            end
            SoundTraceVec = unionByPrefix(Tst, 'sound_trace_');

            % optional unions only
            ShockVec = zeros(nFrames,1,'uint8');
            SoundShockVec = zeros(nFrames,1,'uint8');
            DistractorVec = zeros(nFrames,1,'uint8');

            if ismember(MouseID, DelayGroup)
                Ttmp = table();
                Ttmp = addComponents(Ttmp, Comp1D_SoundShock, nFrames, FPS, SessionName);
                SoundShockVec = unionByPrefix(Ttmp, 'sound_shock');
            end

            if ismember(MouseID, [TraceGroup, DistractorGroup])
                Ttmp = table();
                Ttmp = addComponents(Ttmp, Comp1D_Shock, nFrames, FPS, SessionName);
                ShockVec = unionByPrefix(Ttmp, 'shock');
            end

            if ismember(MouseID, DistractorGroup)
                Ttmp = table();
                Ttmp = addComponents(Ttmp, Comp1D_Distr, nFrames, FPS, SessionName);
                DistractorVec = unionByPrefix(Ttmp, 'distr');
            end

            % final order: general -> detailed
            FeatureTable = table();
            FeatureTable.sound        = SoundVec;
            FeatureTable.trace        = TraceVec;
            FeatureTable.sound_trace  = SoundTraceVec;
            FeatureTable.shock        = ShockVec;
            FeatureTable.sound_shock  = SoundShockVec;
            FeatureTable.distractor   = DistractorVec;
            FeatureTable.ITI          = ITIVec;

            % detailed after general
            for k = 1:7
                FeatureTable.(sprintf('sound%d',k)) = Tbase.(sprintf('sound%d',k));
            end
            for k = 1:7
                FeatureTable.(sprintf('trace%d',k)) = Tbase.(sprintf('trace%d',k));
            end
            for k = 1:7
                FeatureTable.(sprintf('sound_trace_%d',k)) = Tst.(sprintf('sound_trace_%d',k));
            end
            for k = 0:7
                FeatureTable.(sprintf('ITI%d',k)) = Tbase.(sprintf('ITI%d',k));
            end

        case '2D'
            Tbase = table();
            Tbase = addComponents(Tbase, Comp2D, nFrames, FPS, SessionName);

            SoundVec = unionByPrefix(Tbase, 'sound');
            TraceVec = unionByPrefix(Tbase, 'trace');
            ITIVec   = unionByPrefix(Tbase, 'ITI');

            Tst = table();
            for k = 1:7
                sName = sprintf('sound%d', k);
                tName = sprintf('trace%d', k);
                stName = sprintf('sound_trace_%d', k);
                Tst.(stName) = uint8(Tbase.(sName) | Tbase.(tName));
            end
            SoundTraceVec = unionByPrefix(Tst, 'sound_trace_');

            FeatureTable = table();
            FeatureTable.sound       = SoundVec;
            FeatureTable.trace       = TraceVec;
            FeatureTable.sound_trace = SoundTraceVec;
            FeatureTable.ITI         = ITIVec;

            for k = 1:7
                FeatureTable.(sprintf('sound%d',k)) = Tbase.(sprintf('sound%d',k));
            end
            for k = 1:7
                FeatureTable.(sprintf('trace%d',k)) = Tbase.(sprintf('trace%d',k));
            end
            for k = 1:7
                FeatureTable.(sprintf('sound_trace_%d',k)) = Tst.(sprintf('sound_trace_%d',k));
            end
            for k = 0:7
                FeatureTable.(sprintf('ITI%d',k)) = Tbase.(sprintf('ITI%d',k));
            end

        case '3D'
            Tbase = table();
            Tbase = addComponents(Tbase, Comp3D, nFrames, FPS, SessionName);

            ITIVec = unionByPrefix(Tbase, 'ITI');
            DistractorVec = unionByPrefix(Tbase, 'distr');

            FeatureTable = table();
            FeatureTable.distractor = DistractorVec;
            FeatureTable.ITI        = ITIVec;

            for k = 0:20
                FeatureTable.(sprintf('ITI%d',k)) = Tbase.(sprintf('ITI%d',k));
            end

        case '4D'
            FeatureTable = table();
            FeatureTable = addComponents(FeatureTable, Comp4D, nFrames, FPS, SessionName);

        otherwise
            fprintf('Skip unknown day: %s\n', DayID);
            continue;
    end

    outFile = fullfile(OutPath, sprintf('%s_features.csv', SessionName));
    writetable(FeatureTable, outFile);

    fprintf('Saved: %s | columns=%d\n', outFile, width(FeatureTable));
end

disp('Done.');

