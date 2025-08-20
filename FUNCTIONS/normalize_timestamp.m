
function [bufferData, difference] = normalize_timestamp(bufferData)

% normalize timestamp pupdata
% deleting first five rows, this is because of the -!!WEIRD ALERT!!- from the readme file
% 5 samples seems to be a safe amount to exclude
bufferData = bufferData(5:end,:);

% normalize timestamp bc. for some reason it starts at 3000 seconds
time                = 1;   % (VPixx time, in seconds)
difference          = bufferData(1,time);
bufferData(:,time)  = bufferData(:,time)-difference;