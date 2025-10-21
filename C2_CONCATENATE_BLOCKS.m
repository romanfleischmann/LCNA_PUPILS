%% C2 CONCATENATE BLOCKS PER PARTICIPANT
% full disclosure this one is built by AI, but i've checked it
% and it does what it's supposed to be doing, its just incredibly
% inefficient

clear; clc;
tic;
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

% Log file setup
logFile = fullfile(saveFolder, 'concatenation_log.txt');
fid = fopen(logFile, 'w');
fprintf(fid, 'Concatenation Log\n');
fprintf(fid, '=================\n\n');

%--------------------------
% 2. Initialize
%--------------------------
info_con = [];
data_con = [];
currentSubject = '';
currentBase = '';
fileCounter = 0;
currentFiles = {};

% Variables for horizontal concatenation in "info"
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
    
    % Load both info and data
    load(fullfile(sourceFolder, files(i).name), 'info', 'data');
    
    % Initialize first subject/block
    if isempty(currentSubject)
        info_con = info;
        data_con = data;
        currentSubject = info.SUBJECT;
        currentBase = info.baseNameString;
        fileCounter = 1;
        currentFiles = {files(i).name};
        continue;
    end
    
    % Same subject/base and not exceeding max of 5 files
    if strcmp(currentSubject, info.SUBJECT) && strcmp(currentBase, info.baseNameString) && fileCounter < 5
        % Concatenate INFO horizontally
        for v = vars_1x30
            vname = v{1};
            info_con.(vname) = [info_con.(vname), info.(vname)];
        end
        for v = vars_other
            vname = v{1};
            info_con.(vname) = [info_con.(vname), info.(vname)];
        end
        
        % Concatenate DATA
        data_con.trial = [data_con.trial, data.trial];
        data_con.time  = [data_con.time,  data.time];
        % fsample, elec, label, cfg remain unchanged
        
        fileCounter = fileCounter + 1;
        currentFiles{end+1} = files(i).name;
        
    else
        % Make subfolder for baseName (Aoddball or Voddball)
        baseFolder = fullfile(saveFolder, currentBase);
        if ~exist(baseFolder, 'dir')
            mkdir(baseFolder);
        end
        
        % Save current concatenation
        saveFileName = sprintf('concat_%s_%s.mat', currentSubject, currentBase);
        save(fullfile(baseFolder, saveFileName), 'info_con', 'data_con', '-v7.3');
        fprintf('Saved concatenated info/data for %s - %s (%d files)\n', currentSubject, currentBase, fileCounter);
        
        % Log entry
        fprintf(fid, 'Subject: %s | Base: %s | Files combined: %d\n', currentSubject, currentBase, fileCounter);
        for f = 1:length(currentFiles)
            fprintf(fid, '    %s\n', currentFiles{f});
        end
        fprintf(fid, '\n');
        
        % Start new block
        info_con = info;
        data_con = data;
        currentSubject = info.SUBJECT;
        currentBase = info.baseNameString;
        fileCounter = 1;
        currentFiles = {files(i).name};
    end
end

% Save final block
baseFolder = fullfile(saveFolder, currentBase);
if ~exist(baseFolder, 'dir')
    mkdir(baseFolder);
end
saveFileName = sprintf('concat_%s_%s.mat', currentSubject, currentBase);
save(fullfile(baseFolder, saveFileName), 'info_con', 'data_con', '-v7.3');
fprintf('Saved final concatenated info/data for %s - %s (%d files)\n', currentSubject, currentBase, fileCounter);

% Log final block
fprintf(fid, 'Subject: %s | Base: %s | Files combined: %d\n', currentSubject, currentBase, fileCounter);
for f = 1:length(currentFiles)
    fprintf(fid, '    %s\n', currentFiles{f});
end
fprintf(fid, '\n');

% Close log
fclose(fid);

disp('Concatenation complete. Log saved.');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this part takes really long because it reopens every file :(
% 

clear; clc;

%--------------------------
% Setup folders
%--------------------------
baseFolder = 'G:\My Drive\SHARE\SHARE4ANDREW\Fieldtripformat\perpart';
subfolders = {'_Aoddball_', '_Voddball_'}; % Correct folder names with underscores

for s = 1:length(subfolders)
    folderPath = fullfile(baseFolder, subfolders{s});
    
    % Check if subfolder exists
    if ~exist(folderPath, 'dir')
        fprintf('Warning: Folder "%s" does not exist. Skipping...\n', folderPath);
        continue;
    end
    
    files = dir(fullfile(folderPath, 'concat_*.mat'));
    
    if isempty(files)
        fprintf('No files found in %s. Skipping...\n', folderPath);
        continue;
    end
    
    % Storage for percentages
    percentages = [];
    subjects = {};
    
    for i = 1:length(files)
        disp(['Processing file ' num2str(i) ' of ' num2str(length(files)) ': ' files(i).name]);
        
        load(fullfile(folderPath, files(i).name), 'info_con');
        
        % Calculate percentage usable for this file
        perc = mean(info_con.usable) * 100;
        percentages(end+1) = perc;
        
        % Extract subject name
        subjects{end+1} = info_con.SUBJECT;
    end
    
    % Calculate overall average for this condition
    overallAvg = mean(percentages);
    
    % Path for summary text file
    txtFile = fullfile(folderPath, 'usable_summary.txt');
    fid = fopen(txtFile, 'w');
    
    if fid == -1
        error('Could not create summary file in folder: %s', folderPath);
    end
    
    % Write per-subject percentages
    fprintf(fid, 'Usable Trials Summary (%s)\n', subfolders{s});
    fprintf(fid, '==========================\n\n');
    
    for i = 1:length(subjects)
        fprintf(fid, '%s: %.2f%% usable\n', subjects{i}, percentages(i));
    end
    
    % Write overall average
    fprintf(fid, '\nOverall Average: %.2f%% usable\n', overallAvg);
    
    fclose(fid);
    
    disp(['Finished folder: ' subfolders{s} ' — summary saved in usable_summary.txt']);
end
toc;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
