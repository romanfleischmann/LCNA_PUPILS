function [condition1 condition2, stat all_trials1 all_trials2] = clustperm(folderPath, row_nr, variable_condition, cfg, savefig)

% Get a list of all .mat files in the folder
files = dir(fullfile(folderPath, '*.mat'));

all_trials1 = [];
all_trials2 = [];

cnt = 1; % counter
for k = 1:length(files)

    fullFilePath = fullfile(folderPath, files(k).name);  % Full path to the file
    disp(['Loading: ', fullFilePath])
    
    load(fullFilePath);  % Load the .mat file into a struct

    % temp trials is a logical defining the trial which fit our condition
    temp_trials_cond1 = logical(info_con.usable) & logical(info_con.(variable_condition));
    temp_trials_cond2 = logical(info_con.usable) & ~logical(info_con.(variable_condition));

    disp(['trials in condition 1: ', num2str(sum(temp_trials_cond1))]);
    disp(['trials in condition 2: ', num2str(sum(temp_trials_cond2))]);

    % Skip iteration if at least one is entirely false--> this would mean that
    % one condition has no trials
    % if all(~temp_trials_cond1) || all(~temp_trials_cond2)
    %     disp('excluded');
    %     continue;  % Go to next iteration
    % end

    % Skip iteration if at least one condition has less trials than 20
    if sum(temp_trials_cond1)<20 || sum(temp_trials_cond2)<20
        disp('excluded');
        continue;  % Go to next iteration
    end

    % baselining 0 - 3000 ms (grip phase)
    for t = 1:length(data_con.trial)
        data = data_con.trial{1, t}(row_nr,:);        
        baseline = mean(data(1, 1:3000));   % compute baseline for each column
        data_con.trial{1, t}(row_nr,:) = data - baseline; % subtract baseline
    end
    
    % calculate averages per condition
    cfg.trials = temp_trials_cond1;
    conditions{cnt,1} = ft_timelockanalysis(cfg,data_con);

    cfg.trials = temp_trials_cond2;
    conditions{cnt,2} = ft_timelockanalysis(cfg,data_con);

    %%% for plotting:
    selected_trials1 = data_con.trial(temp_trials_cond1);
    selected_trials2 = data_con.trial(temp_trials_cond2);

    % cellfun extract trials
    extracted_rows1 = cellfun(@(x) x(row_nr, :), selected_trials1, 'UniformOutput', false);
    extracted_rows2 = cellfun(@(x) x(row_nr, :), selected_trials2, 'UniformOutput', false);

    % Concatenate rows
    all_trial_temp1 = vertcat(extracted_rows1{:});
    all_trial_temp2 = vertcat(extracted_rows2{:});

    all_trials1 = vertcat(all_trials1, all_trial_temp1);
    all_trials2 = vertcat(all_trials2, all_trial_temp2);
    %%% %%% %%%

    cnt = cnt+1; %countervariable
end

% granaverages per condition and persn
condition1 = ft_timelockgrandaverage(cfg, conditions{:,1})
condition2 = ft_timelockgrandaverage(cfg, conditions{:,2})

%%%%%%%%%%%%%%%%%% PLOTTING

% Compute mean and SEM across trials
n1 = size(all_trials1, 1);
n2 = size(all_trials2, 1);

mean1 = mean(all_trials1, 1);
sem1  = std(all_trials1, [], 1) / sqrt(n1);

mean2 = mean(all_trials2, 1);
sem2  = std(all_trials2, [], 1) / sqrt(n2);

% Time 
t = 1:size(all_trials1, 2);

% Plot
figure; hold on;

% Shaded SEM area for condition 1
fill([t fliplr(t)], [mean1+sem1 fliplr(mean1-sem1)], ...
     [0.2 0.6 1], 'FaceAlpha', 0.25, 'EdgeColor', 'none');

% Shaded SEM area for condition 2
fill([t fliplr(t)], [mean2+sem2 fliplr(mean2-sem2)], ...
     [1 0.4 0.4], 'FaceAlpha', 0.25, 'EdgeColor', 'none');

% Mean lines
plot(t, mean1, 'Color', [0 0.3 0.8], 'LineWidth', 1.8);
plot(t, mean2, 'Color', [0.8 0 0],   'LineWidth', 1.8);

% Add vertical dashed lines
stim1_onset = 3700; % stimulus onset
stim2_onset = 3700 + 600; % stimulus onset (second stimulus)
resp_wind_onset = 3700 + 600 + 350;     % appearance of answer window

xline(stim1_onset, '--k', 'LineWidth', 1.5);
xline(stim2_onset, '--k', 'LineWidth', 1.5);   % black dashed line
xline(resp_wind_onset, '--k', 'LineWidth', 1.5);

% labels and stuff 
xlabel('time (ms)');
ylabel(cfg.channel);
title(['Mean ± SEM Across Trials, condition: ', variable_condition, ', participants: ', num2str(height(conditions))]);
legend({'Cond 1 ± SEM','Cond 2 ± SEM'}, 'Location','best');
grid on; box off;


%% %%%%%%%%%%%%%%%%%%%%%%% CLUSTER BASED PERMUTATION
%cfg         = [];
%cfg.channel = 'dilr';
%cfg.latency = [0 7200];      
cfg.correctm = 'cluster';
%cfg_neighb           = [];         
cfg.method           = 'montecarlo';
cfg.statistic        = 'ft_statfun_depsamplesT';
cfg.correctm         = 'cluster';
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum';
cfg.minnbchan        = 1; %minimum cluster requirement
%cfg.neighbours       = neighbours;  
cfg.tail             = 0;
cfg.clustertail      = 0;
cfg.alpha            = 0.025;
cfg.numrandomization = 1000;

%% design settings
Nsubj  = height(conditions); % however many are still there after exclusions
design = zeros(2, Nsubj*2);
design(1,:) = [1:Nsubj 1:Nsubj];
design(2,:) = [ones(1,Nsubj) ones(1,Nsubj)*2];

cfg.design = design;
cfg.uvar   = 1;   %index in the design, set above
cfg.ivar   = 2;

%% so lets finally do this
[stat] = ft_timelockstatistics(cfg, conditions{:,1}, conditions{:,2})

disp(['number of participants per condition: ', num2str(height(conditions))]);

%% Save figure

fileName = ['fig_', variable_condition, '_', cfg.channel]; 

% Ensure the folder exists
if ~exist(savefig, 'dir')
    mkdir(savefig);
end

figWidth = 14;             % width in inches
figHeight = 4;            % height in inches
dpi = 300;                % resolution for PNG
fig = gcf; % use current figure (or replace with your handle)
set(fig, 'Units', 'inches', 'Position', [1 1 figWidth figHeight]);
set(fig, 'PaperUnits', 'inches', 'PaperSize', [figWidth figHeight], ...
         'PaperPosition', [0 0 figWidth figHeight]);

% === File paths ===
pngFile = fullfile(savefig, [fileName '.png']);

% === Save in both formats ===
exportgraphics(fig, pngFile, 'Resolution', dpi);

fprintf('Saved PNG and SVG to:\n%s\n', savefig);