% PREPROCESSING SKRIPT
clear all

% fot this skript to work the PUPILS toolbox needs to be on the path
% (https://arxiv.org/abs/2011.05118)

% paths for windows
cd('C:\Users\rfleischmann\Documents\GitHub\LCNA_PUPILS') %windowspath
addpath(genpath('C:\Users\rfleischmann\Documents\GitHub\LCNA_PUPILS'))

% folders
targetDir = 'G:\My Drive\SHARE\SHARE4ANDREW\raw';
saveFolder = 'G:\My Drive\SHARE\SHARE4ANDREW\preprocessed';

% all mat files in  folder
files = dir(fullfile(targetDir, '*.mat'));

% Looooop over files
for k = 1:numel(files)
    fileName = files(k).name;
    fullPath = fullfile(targetDir, fileName);
    
    % Print name
    fprintf('Loading file: %s\n', fileName);
    
    % Load
    load(fullPath);
    % clearvars -except SUBJECT audiocompleteTimeD baseName baseNameString bin_buttonpress bin_buttonpress2 blankStartTimeD1 bufferData ButtonResponse ButtonRT ButtonRT2 ConfidenceRate EndofTrial_timeD ExpStartTimeD feedback FeedbackMessage fixStartTimeD1 fname1 grip_baseline grip_duration gripforce_fname GripRelaxTime inter_buttonpress inter_buttonpress2 iscorr isoddball isStrengthHi numCycles numreps numsegs NumStim numTrialReps relaxStartTimeD1 Resp1_Duration Resp1EndTimeD Resp1StartTimeD Resp2_Duration Resp2EndTimeD Resp2StartTimeD SoundStartTimeD SoundStartTimeD1 StimLev StimLev1 stimulusStartTimeD

    % Check if bufferData exists
    if ~exist('bufferData','var')
        fprintf('⚠️ bufferData not found in file: %s\n', fileName);
        continue;  % skip to next iteration
    end

    % normalize timestamppp
    [bufferData, difference] = normalize_timestamp(bufferData);

    % preprocess
    [pupdat, unusable_left, unusable_right] = preprocess(bufferData);
    
    % sync all other timestamps (check whether any timestamps you want to use
    % are here)
    blankStartTimeD1    = blankStartTimeD1  - difference;
    EndofTrial_timeD    = EndofTrial_timeD  - difference;
    ExpStartTimeD       = ExpStartTimeD     - difference;
    fixStartTimeD1      = fixStartTimeD1    - difference;
    relaxStartTimeD1    = relaxStartTimeD1  - difference;
    Resp1EndTimeD       = Resp1EndTimeD     - difference;
    Resp1StartTimeD     = Resp1StartTimeD   - difference;
    Resp2EndTimeD       = Resp2EndTimeD     - difference;
    Resp2StartTimeD     = Resp2StartTimeD   - difference;
    SoundStartTimeD     = SoundStartTimeD   - difference;
    SoundStartTimeD1    = SoundStartTimeD1  - difference;
    stimulusStartTimeD  = stimulusStartTimeD- difference;

    % print the percentage of data that sucks ass
    fprintf('Unusable percentage, left eye: %.4f\n', unusable_left); 
    fprintf('Unusable percentage, right eye: %.4f\n', unusable_right);

    % new file name
    newFileName = [baseName '_prep.mat'];
    savePath = fullfile(saveFolder, newFileName);

    % Clear vars
    clearvars -except targetDir unusable_left unusable_right saveFolder files fileName fullPath newFileName savePath k SUBJECT audiocompleteTimeD baseName baseNameString bin_buttonpress bin_buttonpress2 blankStartTimeD1 ButtonResponse ButtonRT ButtonRT2 ConfidenceRate EndofTrial_timeD ExpStartTimeD feedback FeedbackMessage fixStartTimeD1 fname1 grip_baseline grip_duration gripforce_fname GripRelaxTime inter_buttonpress inter_buttonpress2 iscorr isoddball isStrengthHi numCycles numreps numsegs NumStim numTrialReps relaxStartTimeD1 Resp1_Duration Resp1EndTimeD Resp1StartTimeD Resp2_Duration Resp2EndTimeD Resp2StartTimeD SoundStartTimeD SoundStartTimeD1 StimLev StimLev1 stimulusStartTimeD;

    % Exclude helper variables when saving
    varsToKeep = setdiff(who, {'targetDir','saveFolder','files','fileName','fullPath','newFileName','savePath','k'});
    
    % Save all remaining variables
    save(savePath, varsToKeep{:});
    fprintf('Saved preprocessed file: %s\n\n', savePath);
    
    % Clear vars
    clearvars -except saveFolder files k targetDir;
end

