clear; clc; close all;
addpath(genpath('..\functions'));

is_vsound_known = false;

% read data
[data, timestamps, indexes] = readTIFF_USsignal("..\data\experiment_wo_mocap\test_withMaxime\experiment1\p02_050\", 30, 2500);

% preparing constants
data_spec.n_ust     = size(data, 1);
data_spec.n_samples = size(data, 2);
data_spec.n_frames  = size(data, 3);

if(is_vsound_known)
    us_spec.v_sound                 = 1482.383; % in m/s
    us_spec.sample_rate             = 50 * 1e6;   % in Hz
    us_spec.index2distance_constant = 1e3 * us_spec.v_sound / (2 * us_spec.sample_rate); % 1 sample = this amount distance

    % creating a distance vector for x axis
    xaxis_mm = (1:data_spec.n_samples) .* us_spec.index2distance_constant;
else
    us_spec.sample_rate             = 50 * 1e6;   % in Hz
    us_spec.index2time_constant     = 1/us_spec.sample_rate; % 1 sample = this amount of second (periode, T, basically)

    % creating a time vector for x axis
    xaxis_t  = (1:data_spec.n_samples) .* us_spec.index2time_constant;
end


%% SIGNAL PROCESSING

if(is_vsound_known)
    % load window data
    ust_config = readINI_ustconfig('..\data\experiment_wo_mocap\test_withMaxime\experiment1\watertest_LBUB_050.ini', data_spec);
    % define window range
    ust_config.WindowRange = [ust_config.WindowLowerBound ust_config.WindowUpperBound];
    % convert windows in mm to windows in index
    ust_config.WindowRange_i = floor(ust_config.WindowRange/us_spec.index2distance_constant + 1);
else
    % this is tricky
    ust_config.WindowRange = repmat([5, 7],  data_spec.n_ust, 1) .* 1e-6; % in seconds
    % convert windows in mm to windows in index
    ust_config.WindowRange_i = floor(ust_config.WindowRange/us_spec.index2time_constant + 1);
end

% signal pre-processing
path_barkercode = '..\data\kenans_barkercode.txt';
[allpeaks, envelope_clipped, correlated_clipped] = peaks_USsignal_windowed(data, data_spec, us_spec, ust_config.WindowRange, ust_config.WindowRange_i, path_barkercode);

%% DISPLAY

addpath('..\functions\displays');

% process the data
probeNumber_toShow = 2;

if(is_vsound_known)
    xaxis_clipped = xaxis_mm(ust_config.WindowRange_i(probeNumber_toShow, 1):ust_config.WindowRange_i(probeNumber_toShow, 2));
    display_mode  = 'distance';
else
    xaxis_clipped = xaxis_t(ust_config.WindowRange_i(probeNumber_toShow, 1):ust_config.WindowRange_i(probeNumber_toShow, 2));
    display_mode  = 'time';
end

figure1 = figure(1);
axes1 = axes('Parent', figure1);
for current_frame=1:data_spec.n_frames

    % display a-mode
    display_amode( axes1, ...
                   probeNumber_toShow, ...
                   current_frame, ...
                   correlated_clipped, ...
                   envelope_clipped, ...
                   xaxis_clipped, ...
                   'plot_raw', ...
                   'plot_env');

    % display the peak
	display_peak_amode(axes1, allpeaks, display_mode, probeNumber_toShow, current_frame, 'plot_peak');
    
    if(current_frame==400)
        break;
    end
    
    drawnow;
end






