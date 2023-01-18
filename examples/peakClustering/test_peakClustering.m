% SUMMARY
% This file shows how to use the estimateBoneCluster function to cluster
% multiple layers of detected peaks. Note: this function only can be used
% if you decided to go for OFFLINE measurement.

clc; clear; close all;
addpath('../../functions/signal');
load('peaks_leg02_p28.mat');

% cluster the peaks
clusterparam_dim = 2;
outlierparam_gradthreshold = 5;
outlierparam_minpoint = 10;
[f, data_cleaned] = estimateBoneCluster( allpeaks_peaks, ...
                         clusterparam_dim, ...
                         outlierparam_gradthreshold, ...
                         outlierparam_minpoint, ...
                         true);

% get the usable data
detectedbone_earliest = data_cleaned(1,1);
detectedbone_latest   = data_cleaned(end, 1);
detectedbone_X        = detectedbone_earliest:detectedbone_latest;
detectedbone_Y        = feval(f, detectedbone_X);










