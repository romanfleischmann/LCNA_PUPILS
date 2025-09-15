%%% C1_CONVERT_FIELDTRIP
% this converts one block to fieldtrip

clear all


%%%%%%% PATHS %%%%%%%
% paths for windows 
cd('C:\Users\rfleischmann\Documents\GitHub\LCNA_PUPILS') %windowspath
addpath(genpath('C:\Users\rfleischmann\Documents\GitHub\LCNA_PUPILS'))

% Define source and destination folders
srcFolder = 'G:\My Drive\SHARE\SHARE4ANDREW\preprocessed';
destFolder = 'G:\My Drive\SHARE\SHARE4ANDREW\Fieldtripformat\perblock';

%%%%%%% PATHS END %%%%%%%

% Create destination folder if it does not exist
if ~exist(destFolder, 'dir')
    mkdir(destFolder);
end

% Get list of all .mat files in the source folder
files = dir(fullfile(srcFolder, '*.mat'));

% example fieldtrip structure
load('G:\My Drive\SHARE\SHARE4ANDREW\data_fieldtrip.mat');
data = [];
data = exampleFT;

% these values all relate to timeperiods from the sketched out experimental
% design (LC project eyetracking.pdf), together they form the epoch
trial = 1;
grip = 3000; % ms
blank = 250; % ms
stim1 = 100; % ms
ISI = 500; % ms
stim2 = 100; % ms
blank2 = 250; % ms
resp1 = 3000, % ms (lets see how much sense it makes looking at this period)

length_epoch = grip + blank + stim1 + ISI + stim2 + blank2 + resp1; % this is in ms

tic %this takes long
for i = 1:length(files)
    % Get full path of current file
    srcFile = fullfile(srcFolder, files(i).name);
    
    % Load the file
    fprintf('Processing file: %s\n', files(i).name);
    load(srcFile);

    % downsampling and converting to milliseconds because floating point errors
    % are driving me nuts 
    pupdat = downsample(pupdat,2);
    pupdat(:,1) = pupdat(:,1) * 1000;
    pupdat(:,1) = round(pupdat(:,1)); % rounding to nearest ms
    pupdat(1,:) = []; %now row number = timestamp in ms;
    
    gooddata = [];
    usable = [];
    
    
    for trial = 1:30;
    
        start_epoch = [];
        end_epoch = [];
        
            % find time (start of grip) for the current trial
        start_epoch = stimulusStartTimeD(trial)* 1000; % to ms
        start_epoch = round(start_epoch); % rounding to the nearest millisecond
        
        
        % check whether to use left, right or no eye at all
        % columns 21 and 24 contain whether data is usable (1=yes, 0=no) 
        % see function: preprocess
        % then copy the pupilsize from the "healthy" side (if there is one at all)
        end_epoch = start_epoch+length_epoch-1;
        
        if ~any(pupdat(start_epoch:end_epoch, 21))
            gooddata{trial} = 'left';
            usable(trial) = 1;
            data.trial{1, trial}(1,:) = pupdat(start_epoch:end_epoch, 19)';
        elseif ~any(pupdat(start_epoch:start_epoch+length_epoch, 24))
            gooddata{trial} = 'right';
            usable(trial) = 1;
            data.trial{1, trial}(1,:) = pupdat(start_epoch:end_epoch, 22)';
        else
            gooddata{trial} = 'nothin';
            usable(trial) = 0;
            % if none is good were still copying the left eye as dummy data
            data.trial{1, trial}(1,:) = pupdat(start_epoch:end_epoch, 19)';
        end
        
        % second channel we are approximating a dilation rate!
        dilrate = diff(data.trial{1, trial}(1,:));
        
        %dilrate is missing one sample due to diff(), adding last sample twice to
        %make both arrays equally long. This introduces 0.5 ms of desynchronization, which im choosing to ignore
        dilrate = horzcat(dilrate, dilrate(end));
        
        %add dilrate as second channel to the matrix
        data.trial{1, trial}(2,:) = dilrate;
        
    end
    
    % "data" (main fieldtrip format) done
    % gather all infos to save separately
    
    info.bin_buttonpress2   = bin_buttonpress2;
    info.baseName           = baseName;
    info.baseNameString     = baseNameString;
    info.bin_buttonpress    = bin_buttonpress;
    info.ButtonResponse     = ButtonResponse;
    info.ButtonRT           = ButtonRT;
    info.ButtonRT2          = ButtonRT2;
    info.ConfidenceRate     = ConfidenceRate;
    info.feedback           = feedback;
    info.FeedbackMessage    = FeedbackMessage;
    info.fname1             = fname1;
    info.grip               = grip;
    info.grip_baseline      = grip_baseline;
    info.grip_duration      = grip_duration;
    info.gripforce_fname    = gripforce_fname;
    info.GripRelaxTime      = GripRelaxTime;
    info.inter_buttonpress  = inter_buttonpress;
    info.inter_buttonpress2 = inter_buttonpress2;
    info.iscorr             = iscorr;
    info.isoddball          = isoddball;
    info.isStrengthHi       = isStrengthHi;
    info.numCycles          = numCycles;
    info.numreps            = numreps;
    info.numsegs            = numsegs;
    info.NumStim            = NumStim;
    info.numTrialReps       = numTrialReps;
    info.resp1              = resp1;
    info.StimLev            = StimLev;
    info.StimLev1           = StimLev1;
    info.SUBJECT            = SUBJECT;
    info.Resp1_Duration     = Resp1_Duration;
    info.Resp2_Duration     = Resp2_Duration;
    info.unusable_left      = unusable_left;
    info.unusable_right     = unusable_right;
    info.usable             = usable;
    info.gooddata           = gooddata;
    % get everything thats a timestamp to milliseconds and normalized by
    % stimulusStartTimeD (which is our onset)

    info.stimulusStartTimeD = round(stimulusStartTimeD  * 1000);

    info.EndofTrial_timeD   = round(EndofTrial_timeD    * 1000) - info.stimulusStartTimeD;
    info.blankStartTimeD1   = round(blankStartTimeD1    * 1000) - info.stimulusStartTimeD;
    info.audiocompleteTimeD = round(audiocompleteTimeD  * 1000) - info.stimulusStartTimeD;
    info.relaxStartTimeD1   = round(relaxStartTimeD1    * 1000) - info.stimulusStartTimeD;
    info.Resp1EndTimeD      = round(Resp1EndTimeD       * 1000) - info.stimulusStartTimeD; 
    info.Resp1StartTimeD    = round(Resp1StartTimeD     * 1000) - info.stimulusStartTimeD; 
    info.Resp2EndTimeD      = round(Resp2EndTimeD       * 1000) - info.stimulusStartTimeD;
    info.Resp2StartTimeD    = round(Resp2StartTimeD     * 1000) - info.stimulusStartTimeD;
    info.SoundStartTimeD    = round(SoundStartTimeD     * 1000) - info.stimulusStartTimeD;
    info.SoundStartTimeD1   = round(SoundStartTimeD1    * 1000) - info.stimulusStartTimeD;
    info.ExpStartTimeD      = round(ExpStartTimeD       * 1000) - info.stimulusStartTimeD;
    info.fixStartTimeD1     = round(fixStartTimeD1      * 1000) - info.stimulusStartTimeD;
    
    info.stimulusStartTimeD =  info.stimulusStartTimeD -  info.stimulusStartTimeD; %normalized by itself, so everythings zero

    % Generate new filename with '_FT' added before the extension
    [~, name, ~] = fileparts(files(i).name);
    newName = [name '_FT.mat'];
    
    % Full path for saving
    destFile = fullfile(destFolder, newName);
    
    % Save the 'data' and 'info' structs
    save(destFile, 'data', 'info');
    
    fprintf('Saved processed file to: %s\n', destFile);

    unsable_all(i,1) = unusable_left;
    unsable_all(i,1) = unusable_right;
end
toc
disp('All files processed and saved.');

% this took about 15 minutes


