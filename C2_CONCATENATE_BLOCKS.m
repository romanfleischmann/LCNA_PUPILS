%% C2 CONCATENATE BLOCKS PER PARTICIPANT

clear all

load('G:\My Drive\SHARE\SHARE4ANDREW\Fieldtripformat\perblock\subjectBAP001_Aoddball_session2_run1_8_31_10_43_prep_FT.mat')



% variables to concatenate 1x30
info.usable, info.gooddata, info.stimulusStartTimeD, info.EndofTrial_timeD, info.blankStartTimeD1, info.audiocompleteTimeD, info.relaxStartTimeD1, info.Resp1EndTimeD, info.Resp1StartTimeD, info.Resp2EndTimeD, info.Resp2StartTimeD, info.SoundStartTimeD, info.SoundStartTimeD1, info.ExpStartTimeD, info.fixStartTimeD1

info.StimLev

info.inter_buttonpress, info.inter_buttonpress2, info.iscorr, info.isoddball, info.isStrengthHi
info.ConfidenceRate, info.bin_buttonpress, info.ButtonResponse, info.ButtonRT, info.ButtonRT2
info.bin_buttonpress2

% variables to concatenate other format

info.unusable_right, info.Resp1_Duration, info.Resp2_Duration, info.unusable_left
info.resp1, info.numCycles, info.numreps, info.numsegs, info.NumStim, info.numTrialReps
info.GripRelaxTime
info.grip_duration, info.grip, info.grip_baseline
info.FeedbackMessage, info.feedback


% variables to make sure theyre the same
info.baseNameString
info.SUBJECT


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; clc;

%--------------------------
% 1. Setup paths and files
%--------------------------
sourceFolder = 'G:\My Drive\SHARE\SHARE4ANDREW\Fieldtripformat\perblock';
saveFolder   = 'G:\My Drive\SHARE\SHARE4ANDREW\Fieldtripformat\perpart';

if ~exist(saveFolder, 'dir')
    mkdir(saveFolder);
end

files = dir(fullfile(sourceFolder, '*.mat'));
[~, idx] = sort({files.name});
files = files(idx);

%--------------------------
% 2. Initialize
%--------------------------
currentInfo = [];
currentSubject = '';
currentBase = '';
blockCount = 1;

vars_1x30 = {'usable','gooddata','stimulusStartTimeD','EndofTrial_timeD',...
    'blankStartTimeD1','audiocompleteTimeD','relaxStartTimeD1','Resp1EndTimeD',...
    'Resp1StartTimeD','Resp2EndTimeD','Resp2StartTimeD','SoundStartTimeD',...
    'SoundStartTimeD1','ExpStartTimeD','fixStartTimeD1','StimLev',...
    'inter_buttonpress','inter_buttonpress2','iscorr','isoddball',...
    'isStrengthHi','ConfidenceRate','bin_buttonpress','ButtonResponse',...
    'ButtonRT','ButtonRT2','bin_buttonpress2'};

vars_other = {'unusable_right','Resp1_Duration','Resp2_Duration','unusable_left',...
    'resp1','numCycles','numreps','numsegs','NumStim','numTrialReps',...
    'GripRelaxTime','grip_duration','grip','grip_baseline','FeedbackMessage','feedback'};

%--------------------------
% 3. Loop through all files
%--------------------------
for i = 1:length(files)
    fprintf('Processing file %d of %d: %s\n', i, length(files), files(i).name);
    
    data = load(fullfile(sourceFolder, files(i).name));
    info = data.info;
    
    if isempty(currentInfo)
        currentInfo = info;
        currentSubject = info.SUBJECT;
        currentBase = info.baseNameString;
        continue;
    end
    
    % Check if still same subject & baseNameString
    if strcmp(currentSubject, info.SUBJECT) && strcmp(currentBase, info.baseNameString)
        % Horizontal concatenation for 1x30 variables
        for v = vars_1x30
            vname = v{1};
            currentInfo.(vname) = [currentInfo.(vname), info.(vname)]; % <- horizontal
        end
        
        % Horizontal concatenation for other variables
        for v = vars_other
            vname = v{1};
            currentInfo.(vname) = [currentInfo.(vname), info.(vname)];
        end
    else
        % Save concatenated info
        save(fullfile(saveFolder, sprintf('concat_%s_block%d.mat', currentSubject, blockCount)), 'currentInfo');
        fprintf('Saved concatenated info for %s - block %d\n', currentSubject, blockCount);
        
        % Reset for next subject/block
        blockCount = 1;
        currentInfo = info;
        currentSubject = info.SUBJECT;
        currentBase = info.baseNameString;
    end
end

% Save last accumulated block
save(fullfile(saveFolder, sprintf('concat_%s_block%d.mat', currentSubject, blockCount)), 'currentInfo');
fprintf('Saved final concatenated info for %s - block %d\n', currentSubject, blockCount);

disp('Concatenation complete.');