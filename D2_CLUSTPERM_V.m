clear; clc;

%%%%% FOLDERS %%%%%%
% Specify the folder, either the Oddball folder or the Voddball folder
folderPath = 'G:\My Drive\SHARE\SHARE4ANDREW\Fieldtripformat\perpart\_Voddball_';

% Get a list of all .mat files in the folder
files = dir(fullfile(folderPath, '*.mat'));
%%%%% FOLDERS END %%%%%%

%%%% CLUSTER BASED PERMUTATION FOR DILATION RATE, ODDBALL VS NON-ODDBALL
% set cfg (for fieldtrip)
cfg = [];
cfg.latency = [0 7200]; %this is the epoch set in skript C1
cfg.channel = 'dilr'
row_nr = 2; % for dilation rate, has to fit the "channel" in cfg

% build conditions: here oddball vs non-oddball
variable_condition = 'isoddball';

% run test
[condition1 condition2 stat] = clustperm(folderPath, row_nr, variable_condition, cfg)
