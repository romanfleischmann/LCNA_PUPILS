function [pupdat unusable_left unusable_right] = preprocess(bufferData)

% for this functin to work PUPILs toolbox needs to be accessible
% the function takes -bufferData- and preprocesses it, also calculates how
% much data is unusable (per eye)

% preprocessing steps
% 1. Set all marked "blink" to NaN (per eye)

% 2. Set all values over 1000 to NaN (corrupted data)

% 3. Find more blinks based on the velocity (bc. we do not trust the
% markings from the tracker alone) and set to NaN (per eye)

% 4. interpolate! 
% All periods shorter than 500 ms (1000 samples) with at
% least 100 ms (200 samples) of healthy pupil trace on each side are
% considered good interpolation! :)
% All other areas are considered bad :( and will be marked as excluded. To
% prevent edge-artifacts when filtering bad areas are interpolated
% nevertheless

% 5. Filtering (attenuation above 5 Hz, zero-phase)

%%% COLUMNS %%%

% BufferData = Pupil data
pupdat = bufferData;
% delete "raw" columns
pupdat(:,17:20) = [];

% column names
time      = 1;   % (VPixx time, in seconds)
leftX     = 2;   % Left Eye X (in pixels)
leftY     = 3;   % Left Eye Y (in pixels)
pupleft   = 4;   % Left Pupil Diameter (in pixels)
rightX    = 5;   % Right Eye X (in pixels)
rightY    = 6;   % Right Eye Y (in pixels)
pupright  = 7;   % Right Pupil Diameter
%           8      Digital Input Values (24 bits)
blinkleft = 9;   % Left Blink Detection (0=no, 1=yes)
blinkright= 10;  % Right Blink Detection (0=no, 1=yes)
fixleft   = 12;  % Left Fixation Flag (0=no, 1=yes)
fixright  = 13;  % Right Fixation Flag (0=no, 1=yes)
%           14     Left Eye Saccade Flag (0=no, 1=yes)
%           15     Right Eye Saccade Flag (0=no, 1=yes)
%           16     Message code (integer)

%these ones will be added within this script
velblinkleft    = 17; % blinks detected by velocity change (1=yes, 0=no) 
velblinkright   = 18; % blinks detected by velocity change (1=yes, 0=no) 
pupleft_proc    = 19; % pupleft after processing
pupleft_inter   = 20; % pupleft interpolated areas, safe to use (1=yes, 0=no) 
pupleft_excl    = 21; % pupleft interpolated but NOT safe to use, excluded! (1=yes, 0=no) 
pupright_proc   = 22; % pupright after processing
pupright_inter  = 23; % pupright interpolated areas, safe to use (1=yes, 0=no) 
pupright_excl   = 24; % pupright interpolated but NOT safe to use, excluded! (1=yes, 0=no) 

%% initialize parameters
samplingfreq = 2000; %Hz, because two samples per millisecond. But this does not track with the given frequency (1000 Hz)

%% CLEANING THE EYES
% excluding all data where: 
% - blink = 1
% - values over 1000 units (seems reasonable)

invalid_left = (pupdat(:, blinkleft) == 1) | ... 
               (pupdat(:, pupleft) > 1000);
pupdat(invalid_left, pupleft) = NaN;

invalid_right = (pupdat(:, blinkright) == 1) | ...
                (pupdat(:, pupright) > 1000);
pupdat(invalid_right, pupright) = NaN;

%% Find additional blinks not detected by standard output

% make structure for the toolbox, seperately per eye
time_standIn = 1:height(pupdat); %for some reason PUPILs toolbox does not like our timestamps
pupdat_left = horzcat(time_standIn', pupdat(:,leftX:pupleft)); %time, X, Y, size
pupdat_right = horzcat(time_standIn', pupdat(:,rightX:pupright));

%set structure
options = struct;
options.fs = samplingfreq;                 % sampling frequency (Hz)
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

%find blinks with velocity based function 
% velocities faster than three times the median root mean square value of
% all successive 500 ms windows over the entire trace are marked as blinks
[pupdat_left, info_blinks_left] = detectBlinks(pupdat_left, options);
[pupdat_right, info_blinks_right] = detectBlinks(pupdat_right, options);

pupdat_left(pupdat_left(:,5)>1,5) = 1; %set all blink values (which number the blinks) to 1, so now its: blink (1=yes, 0=no) 
pupdat_right(pupdat_right(:,5)>1,5) = 1; %set all blink values (which number the blinks) to 1, so now its: blink (1=yes, 0=no) 

pupdat = horzcat(pupdat, pupdat_left(:,5)); %add velblinkleft as column 
pupdat = horzcat(pupdat, pupdat_right(:,5)); %add velblinkright as column

% now set all new blinks to NaN as well
pupdat(pupdat(:,velblinkleft) == 1,pupleft) = nan;
pupdat(pupdat(:,velblinkright) == 1,pupright) = nan;

%exclusions done!

%% interpolation
% interpolate short NaN and mark the periods as "good"
[pupleft_interpolated, interpol_good_left] = interpolate_short_nans(pupdat(:,pupleft));
[pupright_interpolated, interpol_good_right] = interpolate_short_nans(pupdat(:,pupright));

% interpolate all other NaN and mark the periods as "bad"
% these are basically excluded periods! Interpolation is just for cleaner
% filtering later on.
[pupleft_interpolated, interpol_bad_left] = interpolate_all_nans_fixed(pupleft_interpolated);
[pupright_interpolated, interpol_bad_right] = interpolate_all_nans_fixed(pupright_interpolated);

% add to main pupdat
pupdat = horzcat(pupdat, pupleft_interpolated, interpol_good_left, interpol_bad_left, pupright_interpolated, interpol_good_right, interpol_bad_right);
clearvars interpol_bad_left interpol_bad_right interpol_good_left interpol_good_right;

%% FILTERING // denoise
% attenuating above 5Hz 

% set filter parameters
fc = 5; % attenuate under 10Hz
[b,a] = butter(4,fc/(samplingfreq/2));

% filter
pupdat(:,pupleft_proc)  = filtfilt(b, a, pupdat(:,pupleft_proc)); % zero-phase filtering, to avoid time lag
pupdat(:,pupright_proc) = filtfilt(b, a, pupdat(:,pupright_proc));

clearvars b a;

%% calculate unusable

unusable_left = (sum(pupdat(:,pupleft_excl))/height(pupdat)) * 100; %percentage of unsuable data, left pupil
unusable_right = (sum(pupdat(:,pupright_excl))/height(pupdat)) * 100; %percentage of unsuable data, left pupil

