function [f, data_cleaned, cluster_idx] = estimateBoneCluster(peaks, clusterparam_dim, outlierparam_gradthresh, outlierparam_minpoint, display)
%ESTIMATEBONECLUSTER A function that cluster the data point from peak
%detection algorithm troughout the time. 
%   From peak detection algorithm, soft tissues and bones, if plotted to a
%   graph, will be presented as curve lines. In the ideal case, you 
%   will see the layers of the curve lines. Our assumption will be: the
%   last curve line is the bone surface. However, to separate the data, we
%   will need to do a clustering first, which will separate the layers,
%   then the last cluster will be assumed to be the bone. In this function,
%   we used DBSCAN as the algorithm.
% 
% INPUT
% peaks                   A Nx3 matrix. Each row represents observation. 
%                         First column is for timestamp, second column is 
%                         for peak location, third column is for peak 
%                         amplitude value.
%
% clusterparam_dim        Either 1 or 2. If you choose 1, the data dimension 
%                         will be reduced into 1 (projected into Y). The 
%                         clustering is simple and faster. However, there 
%                         is no information about curve structure anymore. 
%                         If you choose 2, the data dimension remain the 
%                         same, clustering will be performed using 
%                         Mahalanobis distance with anisotropic covariance 
%                         matrix (elongated in X direction).
%
% outlierparam_gradthres  Outlier is defined as a big jump in the gradient
%                         between the two points in the line. 'Big jump'
%                         defined as the mean of all gradient in the data
%                         times a constant, which we refer to as gradient
%                         treshold.
%
% outlierparam_minpoint   Outlier is not only a big jump, but also a small
%                         clump of data (imagine a data has sudden jump,
%                         and go for 4-5 points, and back to normal again).
%                         To remove this, specify the minimum point.
% 
% display                 For debugging purposes, it will show the figures.
%
% OUTPUT
% f                       A spline interpolation matlab object. To get the
%                         data from this object, use feval(f, X) function.
%
% data_cleaned            A Mx2 matrix, first column is timestamp, second
%                         column is the depth, each rows is observation. 
%                         Cleaned data from outliers, the data that is used
%                         for curve fitting. You can use this data to plot
%                         to the M-mode space image.
%
% cluster_idx             A vector of indices specifying which cluster a 
%                         data point belongs to.


%% 1. CLUSTERING

if(clusterparam_dim==1)
    data_norm = normalize(peaks(:,2));
    epsilon = 0.075;
    minpts = 50;
    cluster_idx = dbscan(data_norm, epsilon, minpts, 'Distance', 'euclidean');
else
    data_norm = normalize(peaks(:,1:2));
    epsilon = 0.1;
    minpts = 30;
    cov = [100 0; 0 1];
    cluster_idx = dbscan(data_norm, epsilon, minpts, 'Distance', 'Mahalanobis', 'Cov', cov);
end

%% 2. LABEL THE CLUSTER

% 2.1) Get the Mean of all cluster we have --------------------------------

% get the label number (which automatically assigned by matlab)
cluster_labels  = unique(cluster_idx);
cluster_n       = length(cluster_labels);
% prepare some variables
cluster_mean    = [0];
cluster_current = 2;
% for each cluster, we compute the mean
while (cluster_current <= cluster_n)
    member_clusteridx = find(cluster_idx==cluster_labels(cluster_current));
    member_cluster    = peaks(member_clusteridx, : );
    cluster_mean      = [ cluster_mean; mean(member_cluster(:,2))];
    
    cluster_current = cluster_current + 1;
end

% 2.2) Based on the mean we obtaned, we sort our cluster ------------------

% sort the mean
[~, sort_idx]               = sort(cluster_mean);
% make a new label
cluster_newlabels           = 1:length(cluster_mean);
cluster_newlabels(sort_idx) = cluster_newlabels + 99;
% for each cluster, assign new label
cluster_current = 2;
while (cluster_current <= cluster_n)
    cluster_currentlabel = cluster_labels(cluster_current);
    cluster_idx(cluster_idx==cluster_currentlabel) = cluster_newlabels(cluster_current);

    cluster_current = cluster_current + 1;
end

% 2.3) Get the latest cluster, we assumed it is the bone ------------------

cluster_labels    = unique(cluster_idx);
cluster_select    = cluster_labels(end);
member_clusteridx = find(cluster_idx==cluster_select);
member_cluster    = peaks(member_clusteridx, : );

%% 3. REMOVING OUTLIERS AND FITTING

% calculate gradient 
gradients = [member_cluster(1:end-1,1), abs(diff(member_cluster(:,2)))];

% calculate the mean of the gradient to define outlier threshold
gradients_mean    = mean(gradients(:,2));
outliers          = [0; find(gradients(:,2)>=gradients_mean*outlierparam_gradthresh); length(gradients)+1];

% value within outliers variable will be a 'border', so that we only take
% data in between 'border'. We do this because we also want to reject
% small-clumped data, which sometimes can't be remove with regular outlier
% removal function from matlab.
group_member_cleaned  = {};
for i=1:length(outliers)-1
    tmp = member_cluster( outliers(i)+1: outliers(i+1)-1, :);
    if(length(tmp) >= outlierparam_minpoint)
        group_member_cleaned{i} = tmp;
    end
end
data_cleaned = cell2mat(group_member_cleaned');

% we assume the data is better now, so let's fit the curve
if(~isempty(data_cleaned))
    f = fit( data_cleaned(:,1), ...
             data_cleaned(:,2), ...
             'smoothingspline','SmoothingParam',0.005);
else
    f = [];
end

%% 4. DISPLAY (FOR DEBUGGING PURPOSE)

if (display)
    f_x = peaks(1,1):peaks(end,1);
    f_y = feval(f, f_x);

    % prepare window
    figure1 = figure('Name', 'Cleaning and Clustering', 'Position', [100 100 1200 600]);
    %figure1.WindowState = 'maximized';
    
    subplot_rows  = 3;
    subplot_cols  = 2;
    subplot_index = reshape(1:(subplot_rows*subplot_cols), subplot_cols, subplot_rows)';
    
    subplotidx_clustering = subplot_index(1:3,1);
    subplotidx_noisypeaks = subplot_index(1,2);
    subplotidx_gradient   = subplot_index(2,2);
    subplotidx_cleanpeaks = subplot_index(3,2);

    ax_clustering = subplot(subplot_rows, subplot_cols, subplotidx_clustering, 'Parent', figure1);
    ylabel(ax_clustering, 'Time ($\mu$s)', 'Interpreter', 'Latex');
    xlabel(ax_clustering, 'Timestamp');
    title(ax_clustering, 'Ultrasound Peaks');
    ylim(ax_clustering, [0 20]*1e-6);
    xlim(ax_clustering, [peaks(1,1), peaks(end,1)]);
    grid(ax_clustering, 'on');
    ax_clustering.XMinorGrid = 'on';
    hold(ax_clustering, 'on');
    gscatter(ax_clustering, peaks(:,1), peaks(:,2), cluster_idx);
    plot(ax_clustering, f_x, f_y, '-r');
    
    ax_noisypeaks = subplot(subplot_rows, subplot_cols, subplotidx_noisypeaks, 'Parent', figure1);
    ylabel(ax_noisypeaks, 'Time ($\mu$s)', 'Interpreter', 'Latex');
    xlabel(ax_noisypeaks, 'Data Index');
    title(ax_noisypeaks, 'Noisy Estimated Bone (time vs index)');
    grid(ax_noisypeaks, 'on');
    ax_noisypeaks.XMinorGrid = 'on';
    axis(ax_noisypeaks, 'tight');
    hold(ax_noisypeaks, 'on');
    plot(ax_noisypeaks, 1:length(member_cluster(:,2)), member_cluster(:,2), '.r');

    ax_gradient   = subplot(subplot_rows, subplot_cols, subplotidx_gradient, 'Parent', figure1);
    ylabel(ax_gradient, 'Normalized Gradient');
    xlabel(ax_gradient, 'Data Index');
    title(ax_gradient, 'Gradient for each two consecutive data point');
    grid(ax_gradient, 'on');
    ax_gradient.XMinorGrid = 'on';
    axis(ax_gradient, 'tight');
    hold(ax_gradient, 'on');
    plot(ax_gradient, 1:length(gradients(:,2)), gradients(:,2));
    yline(ax_gradient, gradients_mean*5, '--r', 'Threshold', 'LineWidth', 1);
    
    ax_cleanpeaks = subplot(subplot_rows, subplot_cols, subplotidx_cleanpeaks, 'Parent', figure1);
    ylabel(ax_cleanpeaks, 'Time ($\mu$s)', 'Interpreter', 'Latex');
    xlabel(ax_cleanpeaks, 'Timestamp');
    title(ax_cleanpeaks, 'Cleared Estimated Bone with Curve Fitting');
    grid(ax_cleanpeaks, 'on');
    ax_cleanpeaks.XMinorGrid = 'on';
    axis(ax_cleanpeaks, 'tight');
    hold(ax_cleanpeaks, 'on');
    plot(ax_cleanpeaks, data_cleaned(:,1), data_cleaned(:,2), '.r');
    plot(ax_cleanpeaks, f_x, f_y, '-r');

end


end

