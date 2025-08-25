%%% C1_CONVERT_FIELDTRIP

clear all

% paths for windows 
cd('C:\Users\rfleischmann\Documents\GitHub\LCNA_PUPILS') %windowspath
addpath(genpath('C:\Users\rfleischmann\Documents\GitHub\LCNA_PUPILS'))

% example fieldtrip structure
load('G:\My Drive\SHARE\SHARE4ANDREW\data_fieldtrip.mat');
data = exampleFT;

trial = 1;
length_epoch = 14400; % this is in samples not ms

% find time (start of grip) for the current trial
start_epoch = stimulusStartTimeD(trial);
start_epoch = start_epoch -0.0001; % something is off with the times, by 1 millisecond (i assume), were rounding but it seems like a hack :(

% this clears up some weird floating point errors at the 17th decimal
pupdat(:,1) = round(pupdat(:,1),4); 
start_epoch = round(start_epoch,4);

%find the row from where the data for our trial starts
row_number = find(pupdat(:,1) == start_epoch);

% check whether to use left, right or no eye at all
% columns 21 and 24 contain whether data is usable (1=yes, 0=no) 
% see function: preprocess
% then copy the pupilsize from the "healthy" side (if there is one at all)

row_number_end = row_number+length_epoch-1;

if ~any(pupdat(row_number:row_number_end, 21))
    gooddata = 'left';
    usable(trial) = 1;
    data.trial{1, trial}(1,:) = pupdat(row_number:row_number_end, 19)';
elseif ~any(pupdat(row_number:row_number+length_epoch, 24))
    gooddata = 'right';
    usable(trial) = 1;
    data.trial{1, trial}(1,:) = pupdat(row_number:row_number_end, 22)';
else
    gooddata = 'none';
    usable(trial) = 0;
    % if none is good were still copying the left eye as dummy data
    data.trial{1, trial}(1,:) = pupdat(row_number:row_number_end, 19)';
end

% second channel we are approximating a dilation rate!
dilrate = diff(data.trial{1, trial}(1,:));

%dilrate is missing one sample due to diff(), adding last sample twice to
%make both arrays equally long. This introduces 0.5 ms of desynchronization, which im choosing to ignore
dilrate = horzcat(dilrate, dilrate(end));

%add dilrate as second channel to the matrix
data.trial{1, trial}(2,:) = dilrate;






SoundStartTimeD1 - stimulusStartTimeD



