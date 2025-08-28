%% D1 ANALYSIS 1


clear; clc;

cfg = [];
cfg.latency = [0 7200];


% Specify the folder
folderPath = 'G:\My Drive\SHARE\SHARE4ANDREW\Fieldtripformat\perpart\_Aoddball_';

% Get a list of all .mat files in the folder
files = dir(fullfile(folderPath, '*.mat'));

cnt = 1; % counter
for k = 1:length(files)

    

    fullFilePath = fullfile(folderPath, files(k).name);  % Full path to the file
    disp(['Loading: ', fullFilePath])
    
    load(fullFilePath);  % Load the .mat file into a struct

    % temp trials is a logical defining the trial which fit our condition
    %temp_trials_cond1 = logical(info_con.usable) & logical(info_con.isStrengthHi);
    %temp_trials_cond2 = logical(info_con.usable) & ~logical(info_con.isStrengthHi);

    temp_trials_cond1 = logical(info_con.usable) & logical(info_con.isoddball);
    temp_trials_cond2 = logical(info_con.usable) & ~logical(info_con.isoddball);

    % Skip iteration if both are entirely false --> this would mean that
    % one condition has no trials
      % Skip iteration if at least one is entirely false
    if all(~temp_trials_cond1) || all(~temp_trials_cond2)
        continue;  % Go to next iteration
    end

    % baselining 0 - 3000 ms (grip phase)
    for t = 1:length(data_con.trial)
        data = data_con.trial{1, t}(1,:);        
        baseline = mean(data(1, 1:3000));   % compute baseline for each column
        data_con.trial{1, t}(1,:) = data - baseline; % subtract baseline
    end
    
    % calculate averages per condition
    cfg.trials = temp_trials_cond1;
    conditions{cnt,1} = ft_timelockanalysis(cfg,data_con);

    cfg.trials = temp_trials_cond2;
    conditions{cnt,2} = ft_timelockanalysis(cfg,data_con);

    cnt = cnt+1;
end
  
cfg = [];
cfg.latency = [0 7200];
condition1 = ft_timelockgrandaverage(cfg, conditions{:,1})

cfg = [];
cfg.latency = [0 7200];
condition2 = ft_timelockgrandaverage(cfg, conditions{:,2})

%%%%%%%%%%%%%%%%%% PLOTTING

% Extract time and average across channels
time = condition1.time;
data1 = mean(condition1.avg, 1);   % average across channels
data2 = mean(condition2.avg, 1);

figure; hold on;

% Plot condition1 in blue
plot(time, data1, 'b', 'LineWidth', 2);

% Plot condition2 in red
plot(time, data2, 'r', 'LineWidth', 2);

% Add vertical dashed lines

stim1_onset = 3700; % stimulus onset
stim2_onset = 3700 + 600; % stimulus onset (second stimulus)
resp_wind_onset = 3700 + 600 + 350;     % appearance of answer window

xline(stim1_onset, '--k', 'LineWidth', 1.5);
xline(stim2_onset, '--k', 'LineWidth', 1.5);   % black dashed line
xline(resp_wind_onset, '--k', 'LineWidth', 1.5);


xlabel('Time (ms)');
ylabel('Amplitude');
title('Comparison of Conditions');
legend({'Condition 1','Condition 2'});
grid on;

%%%%%%%%%%%%%%%%%%%%%%%%% CLUSTER BASED PERMUTATION

cfg         = [];
cfg.channel = 'size';
cfg.latency = [0 7200];      
cfg.correctm = 'no';
cfg_neighb        = [];         
cfg.method           = 'montecarlo';
%cfg.statistic        = 'ft_statfun_depsamplesFunivariate';  %possible statistics, choose your warrior
%cfg.statistic        =  'ft_statfun_indepsamplesF'
cfg.statistic        = 'ft_statfun_depsamplesT';
cfg.correctm         = 'cluster';
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum';
cfg.minnbchan        = 1; %minimum cluster requirement
cfg.neighbours       = neighbours;  % same as defined for the between-trials experiment
cfg.tail             = 0;
cfg.clustertail      = 0;
cfg.alpha            = 0.05;
cfg.numrandomization = 1000;


%% design settings

Nsubj  = 37;
design = zeros(2, Nsubj*2);
design(1,:) = [1:Nsubj 1:Nsubj];
design(2,:) = [ones(1,Nsubj) ones(1,Nsubj)*2];

cfg.design = design;
cfg.uvar   = 1;   %index in the design, set above
cfg.ivar   = 2;

%% so lets finally do this


[stat] = ft_timelockstatistics(cfg, conditions{:,1}, conditions{:,2})






cfg         = [];
cfg.channel = 'size';
cfg.latency = [0 2.5];           % the data is already shortened to the epoch 0-0.5, so were doing the whole length yeeehaaaaw

cfg_neighb        = [];         
cfg_neighb.method = 'distance';
%cfg.feedback = 'yes';
neighbours        = ft_prepare_neighbours(cfg_neighb, conditions{1,2});

cfg.neighbours    = neighbours;  % the neighbours specify for each sensor with
                                 % which other sensors it can form clusters

cfg.method           = 'montecarlo';
cfg.statistic        = 'depsamplesT';
cfg.correctm         = 'no';
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum';
%cfg.minnbchan        = 1; %minimum cluster requirement
cfg.neighbours       = neighbours;  % same as defined for the between-trials experiment
cfg.tail             = 0;
cfg.clustertail      = 0;
cfg.alpha            = 0.05;
cfg.numrandomization = 1000;

design = []
Nsubj  = 64;
design = zeros(2, Nsubj*2);
design(1,:) = [1:Nsubj 1:Nsubj ];
design(2,:) = [ones(1,Nsubj) ones(1,Nsubj)*2];

cfg.design = design;
cfg.uvar   = 1;   %index in the design, set above
cfg.ivar   = 2;
