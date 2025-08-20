%% PREPROCESS
addpath("/Users/romanfleischmann/Desktop/BOSTONCOLLAB") ;


load('/Users/romanfleischmann/Library/CloudStorage/GoogleDrive-fleischmann.roman@gmail.com/My Drive/SHARE/SHARE4ANDREW/raw/subjectBAP107_Voddball_session2_run5_8_29_10_52.mat')
clearvars -except bufferData

% BufferData = Pupil data
% columns are this:
time      = 1;   % (VPixx time, in seconds)
leftX     = 2;   % Left Eye X (in pixels)
leftY     = 3;   % Left Eye Y (in pixels)
pupleft   = 4;   % Left Pupil Diameter (in pixels)
leftX     = 5;   % Right Eye X (in pixels)
leftY     = 6;   % Right Eye Y (in pixels)
pupright  = 7;   % Right Pupil Diameter
blinkleft = 9;   % Left Blink Detection (0=no, 1=yes)
blinkright= 10;  % Right Blink Detection (0=no, 1=yes)
fixleft   = 12;  % Left Fixation Flag (0=no, 1=yes)
fixright  = 13;  % Right Fixation Flag (0=no, 1=yes)

% deleting first five rows, this is because of the -!!WEIRD ALERT!!- from the readme file
% 5 samples seems to be a safe amount to exclude
pupdat = bufferData(10:end,:);

% normalize timestamp bc. for some reason it starts at 3000 seconds
% from the timestamp i am assuming the sampling frequency to be 2000Hz!!
% (DOUBLECHECK THIS)
pupdat(:,1)=pupdat(:,1)-pupdat(1,1);

% --- CLEANING THE EYES ---
% excluding all data where: 
% - blink = 1
% - fixation = 0
% - values over 1000 units (seems reasonable)

invalid_left = (pupdat(:, blinkleft) == 1) | ... 
               (pupdat(:, pupleft) > 1000);
pupdat(invalid_left, pupleft) = NaN;

invalid_right = (pupdat(:, blinkright) == 1) | ...
                (pupdat(:, pupright) > 1000);
pupdat(invalid_right, pupright) = NaN;

%%%% not excluding the non-fixated periods after all, bc seems to exclude A LOT
% invalid_left = (pupdat(:, fixleft) == 0);
% pupdat(invalid_left, pupleft) = NaN;
% invalid_right = (pupdat(:, fixright) == 0);
% pupdat(invalid_right, pupright) = NaN;

%% Find additional blinks not detected by standard output
% path to PUPILs toolbox
% INSERT WEBSITE HERE
addpath("/Users/romanfleischmann/Desktop/BOSTONCOLLAB/PUPILS-preprocessing-pipeline-master") ;


% make structure for the toolbox, seperately per eye
time_standIn = 1:height(pupdat);
pupdat_left = horzcat(time_standIn', pupdat(:,2:4)); %time, X, Y, size
pupdat_right = horzcat(time_standIn', pupdat(:,5:7));

%set structure
options = struct;
options.fs = 2000;                 % sampling frequency (Hz)
options.blink_rule = 'vel';       % Rule for blink detection 'std' / 've
% options.pre_blink_t   = 100;      % region to interpolate before blink (ms)
% options.post_blink_t  = 200;      % region to interpolate after blink (ms)
% options.xy_units = 'px';          % xy coordinate units 'px' / 'mm' / 'cm'
% % options.vel_threshold =  30;      % velocity threshold for saccade detection
% options.min_sacc_duration = 10;   % minimum saccade duration (ms)
% options.interpolate_saccades = 0; % Specify whether saccadic distortions should be interpolated 1-yes 0-noB
% options.pre_sacc_t   = 50;        % Region to interpolate before saccade (ms)
% options.post_sacc_t  = 100;       % Region to interpolate after saccade (ms)
% options.low_pass_fc   = 10;       % Low-pass filter cut-off frequency (Hz)
% options.screen_distance = 7000; % Screen distance in mm %%THIS IS AN ESTIMATE; CHANGE FOR REAL VALUE ONCE YOU FIND OUT
% options.dpi = 72; % pixels/inches %THIS IS AN ESTIMATE; CHANGE FOR REAL VALUE ONCE YOU FIND OUT
% 
% [pupdat_left_proc pupdat_left_info] = processPupilData(pupdat_left, options);


%%% INSERT A TEMPORARY FILTERING HERE THAT CAN HANDLE NANs %%%

%find blinks with velocity based function 
% velocities faster than three times the median root mean square value of
% all successive 500 ms windows over the entire trace are marked as blinks
[pupdat_left, info_blinks_left] = detectBlinks(pupdat_left, options);
[pupdat_right, info_blinks_right] = detectBlinks(pupdat_right, options);

pupdat_left(pupdat_left(:,5)>1,5) = 1; %set all blink values (which number the blinks) to 1, so now its: blink (1=yes, 0=no) 
pupdat_right(pupdat_right(:,5)>1,5) = 1; %set all blink values (which number the blinks) to 1, so now its: blink (1=yes, 0=no) 

pupdat = horzcat(pupdat, pupdat_left(:,5)); %add left as column 21
pupdat = horzcat(pupdat, pupdat_right(:,5)); %add right as column 22

% now set all new blinks to NaN as well
pupdat(pupdat(:,21) == 1,4) = nan;
pupdat(pupdat(:,22) == 1,4) = nan;

%% exclusions done!

%% interpolation

[pupleft_interpolated, interpol_good_left] = interpolate_short_nans(pupdat(:,4));
[pupright_interpolated, interpol_good_right] = interpolate_short_nans(pupdat(:,7));

[pupleft_interpolated, interpol_bad_left] = interpolate_all_nans(pupleft_interpolated);
[pupright_interpolated, interpol_bad_right] = interpolate_all_nans(pupright_interpolated);


pupdat = horzcat(pupdat, pupleft_interpolated, interpol_good_left, interpol_bad_left, pupright_interpolated, interpol_good_right, interpol_bad_right);


%% FILTERING HERE
tmp = pupdat(:,23);
new_column = size(tmp, 2) +1;

fc = 4
fs = 2000 %% again an ASSUMPTION FROM THE PROVIDED TIMES; ASK IF THIS IS TRUE
[b,a] = butter(4,fc/(fs/2));
tmp(:, new_column) = filtfilt(b, a, tmp(:, new_column-1)); % zero-phase filtering, to avoid time lag
pupdat(:,23) = tmp;

plot(1:height(tmp), tmp(:,2))
hold on
plot(1:height(tmp), tmp(:,1))
hold off

plot(time_standIn, pupdat(:,4))
hold on;
plot(time_standIn, pupdat(:,23)-5)
hold off;








