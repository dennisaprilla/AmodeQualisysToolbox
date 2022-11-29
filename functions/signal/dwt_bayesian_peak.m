function [peak_bayes, peak_dists] = dwt_bayesian_peak(mra, mra_sel, isWeighted, index2distance_constant)
%DWT_BAYESIAN_PEAK Summary of this function goes here
%   Detailed explanation goes here

    % obtain how many mra level we have
    mra_level = size(mra,1);

    % variable to store peak distributions
    peak_dists = [];
    
    % constant for envelope and smoothing
    start = 5;
    step  = 5;
    peak_alg = 'analytic';
    envconstants = start + (0:step:(mra_level-1)*step);
    start = 3;
    step  = 3;
    gausswindows =  start + (0:step:(mra_level-1)*step);
    
    % constant for find peaks
    n_peaks = 5;
    min_peak_prominence = 0.4;
    
    % constant for weighting the peak
    % w_factor   = [1 2 3 4 5];

    % loop for every mra level
    for mra_idx = 1:mra_level
        
        % i only take mra level that is specified in mra_sel
        if( find(mra_sel==mra_idx) )
            
            % obtain current mra level
            current_mra  = mra(mra_idx,:);
            
            % envelope the signal
            current_mra_env  = smoothdata( ...
                                    envelope( current_mra, ...
                                    envconstants(mra_idx), peak_alg ), ...
                               'gaussian', gausswindows(mra_idx));
            current_mra_norm = current_mra_env ./ max(current_mra_env);
            
            % find peaks
            [~, loc, w, ~] =  findpeaks( current_mra_norm, ...
                                         'NPeaks', n_peaks, ...
                                         'MinPeakProminence', min_peak_prominence, ...
                                         'SortStr', 'descend');
            % location are in sample, convert it to distance
            loc_mm   = loc*index2distance_constant;
            
            % fit the peaks to gaussian
            if(length(loc_mm)>1)
                
                % if weighted, use the weight factor
                if (isWeighted)
                    
                    % calculate the weight factor
                    w_norm   = w ./ max(w);
                    w_factor = floor( current_mra_norm(loc) .* w);
                    % w_factor = floor( 10 * current_mra_norm(loc) .* (1 ./ (w_norm)) ).^2;
                    
                    new_loc_mm = [];
                    for i=1:length(w_factor)
                        for j=1:w_factor(i)
                            new_loc_mm = [new_loc_mm, loc_mm(i)];
                        end
                    end
                    [mu_peak, sigma_peak] = normfit(new_loc_mm);
                    
                % if not, treat every peak equally
                else
                    [mu_peak, sigma_peak] = normfit(loc_mm);
                end
            else
                mu_peak = loc_mm;
                sigma_peak = 1; % in mm unit
            end
            
            % if there is no peak, no need to store the values
            if(~isempty(loc_mm))                
                peak_dists = [peak_dists; mu_peak, sigma_peak];
            end
        
        % end if mra level selection
        end
    % end loop for mra level  
    end
    
    % do bayesian inference for peak distributions for every level
    postMean = peak_dists(1,1);
    postSD   = peak_dists(1,2);
    for peak_dists_idx = 2:size(peak_dists,1)        
        [postMean, postSD] = bayes_inference( postMean, postSD, ...
                                              peak_dists(peak_dists_idx, 1), ...
                                              peak_dists(peak_dists_idx, 2) );
    end
    peak_bayes = [postMean, postSD];
    
    
% end function
end

