function [all_bonepeak, all_ampidx, all_window] = peaks_USsignal_offline(data, data_spec, us_spec, processmode)

% pre-allocation variables, later can be deleted
all_bonepeak = cell(data_spec.n_ust, 1);
all_ampidx   = cell(data_spec.n_ust, 1);
all_window   = ones(data_spec.n_ust, 2);

% construct sigmoid filter
sigFilt = sigmoid_simple(size(data,2), 2.0, 0.1, 1/us_spec.sample_rate);

% to see the time
t_dsp  = zeros(data_spec.n_frames, 1);
t_peak = zeros(data_spec.n_frames, 1);

% put indicator to terminal
disp("DSP is running, please wait ...");

% show the progress bar, so that the user is not bored
f = waitbar(0, sprintf('%d/%d Probe', 0, data_spec.n_ust), 'Name', 'Running DSP');

warning('off', 'signal:findpeaks:largeMinPeakHeight');

% start the looop ---------------------------------------------------------
for current_probe=1:data_spec.n_ust

    % display progress bar
    waitbar( current_probe/data_spec.n_ust, f, sprintf('%d/%d Probe', current_probe, data_spec.n_ust) );
    
    % to collect peaks
    allpeaks_wo_echo = [];

    % start DSP ----------------------------------------------------------------------------------------------------------------
    tic;
    for current_frame=1:data_spec.n_frames

        % default requires envelope data
        if(strcmp(processmode, 'default'))

            % 1) grab processed data
            USsignals_envelop = data(current_probe,:,current_frame);

            % 2) peak detection
            [peak_amp, peak_loc, w, p] = findpeaks( USsignals_envelop, ...
                                                    us_spec.sample_rate, ...
                                                    'MinPeakHeight', 500, ...
                                                    'MinPeakProminence', 750, ...
                                                    'MinPeakDistance', 0.65e-6);

            % 2.2) Eliminate very fat peaks
            peaks_ratio = (p*1e-3) ./ (w*1e6);
            peaks_ratiotresh = 0.15;
            peak_amp(peaks_ratio < peaks_ratiotresh)  = [];
            peak_loc(peaks_ratio < peaks_ratiotresh) = [];
            % 2.3) Eliminate echo
            [peak_idx_softtissues, peak_idx_bone, ~] = eliminatePeakEcho(peak_amp, peak_loc, 0.5, 0.75);
            % 2.4) Collect the results
            allpeaks_wo_echo = [ allpeaks_wo_echo; ...
                                 repmat(current_frame, length(peak_idx_softtissues), 1), peak_loc(peak_idx_softtissues)'; ...
                                 repmat(current_frame, length(peak_idx_bone), 1), peak_loc(peak_idx_bone)' ];

        elseif(strcmp(processmode, 'cwt1'))
            
            % 1.1) Filter raw data with sigmoid
            USsignals_sigfilter = data(current_probe,:,current_frame) .* sigFilt;

            % 1.2) CWT
            [cfs, ~] = cwt(USsignals_sigfilter, us_spec.sample_rate, 'FrequencyLimit', [7.0e6, 7.3e6], 'VoicesPerOctave', 48);
            % 1.3) "Envelope"
            USsignals_envelop = mean(abs(cfs), 1);

            % 2.1) Find peaks
            [peak_amp, peak_loc, w, p] = findpeaks( USsignals_envelop, ...
                                                    us_spec.sample_rate, ...
                                                    'MinPeakHeight', 100, ...
                                                    'MinPeakProminence', 130, ...
                                                    'MinPeakDistance', 0.65e-6);

            % 2.2) Eliminate very fat peaks
            peaks_ratio = (p*1e-3) ./ (w*1e6);
            peaks_ratiotresh = 0.2;
            peak_amp(peaks_ratio < peaks_ratiotresh)  = [];
            peak_loc(peaks_ratio < peaks_ratiotresh) = [];
            % 2.3) Eliminate echo
            [peak_idx_softtissues, peak_idx_bone, ~] = eliminatePeakEcho(peak_amp, peak_loc, 0.15, 0.75);
            % 2.4) Collect the results
            allpeaks_wo_echo = [ allpeaks_wo_echo; ...
                                 repmat(current_frame, length(peak_idx_softtissues), 1), peak_loc(peak_idx_softtissues)'; ...
                                 repmat(current_frame, length(peak_idx_bone), 1), peak_loc(peak_idx_bone)' ];

        elseif(strcmp(processmode, 'cwt2'))

            % 1.1) Filter raw data with sigmoid
            USsignals_sigfilter = data(current_probe,:,current_frame) .* sigFilt;

            % 1.2) CWT
            [cfs1, ~] = cwt(USsignals_sigfilter, us_spec.sample_rate, 'FrequencyLimit', [5.3e6, 5.6e6], 'VoicesPerOctave', 48);
            [cfs2, ~] = cwt(USsignals_sigfilter, us_spec.sample_rate, 'FrequencyLimit', [7.0e6, 7.3e6], 'VoicesPerOctave', 48);
            cfs_mag_mean1 = mean(abs(cfs1), 1);
            cfs_mag_mean2 = mean(abs(cfs2), 1);
            % 1.3) "Envelope"
            USsignals_envelop  = max([cfs_mag_mean1;cfs_mag_mean2], [], 1);

            % 2.1) Find peaks
            [peak_amp, peak_loc, w, p] = findpeaks( USsignals_envelop, ...
                                                    us_spec.sample_rate, ...
                                                    'MinPeakHeight', 100, ...
                                                    'MinPeakProminence', 130, ...
                                                    'MinPeakDistance', 0.65e-6);

            % 2.2) Eliminate very fat peaks
            peaks_ratio = (p*1e-3) ./ (w*1e6);
            peaks_ratiotresh = 0.2;
            peak_amp(peaks_ratio < peaks_ratiotresh)  = [];
            peak_loc(peaks_ratio < peaks_ratiotresh) = [];
            % 2.3) Eliminate echo
            [peak_idx_softtissues, peak_idx_bone, ~] = eliminatePeakEcho(peak_amp, peak_loc, 0.15, 0.75);
            % 2.4) Collect the results
            allpeaks_wo_echo = [ allpeaks_wo_echo; ...
                                 repmat(current_frame, length(peak_idx_softtissues), 1), peak_loc(peak_idx_softtissues)'; ...
                                 repmat(current_frame, length(peak_idx_bone), 1), peak_loc(peak_idx_bone)' ];

        end



        % disp(current_frame);

    end
    % storing the duration time for DSP
    t_dsp(current_probe) = toc;
    % -------------------------------------------------------------------------------------------------------

    % flag
    isPostprocess = false;

    % do post-processing if there are peaks that is detected -------------------------------------------------
    tic;
    if(~isempty(allpeaks_wo_echo))
        % 3.1) Cleaning the outliers
        clusterparam_dim           = 2;
        outlierparam_gradthreshold = 5;
        outlierparam_minpoint      = 10;
        [f_fit, data_cleaned, ~]       = estimateBoneCluster( allpeaks_wo_echo, ...
                                                              clusterparam_dim, ...
                                                              outlierparam_gradthreshold, ...
                                                              outlierparam_minpoint, ...
                                                              false);
        % continue post-processing if curve can be fitted to the data
        if(~isempty(f_fit))
            % 3.2) Get the useable data
            detectedbone_earliest = data_cleaned(1,1);
            detectedbone_latest   = data_cleaned(end, 1);
            detectedbone_X        = detectedbone_earliest:detectedbone_latest;
            detectedbone_Y        = feval(f_fit, detectedbone_X);
        
            % 3.3) Get the window
            window_critical       = [min(detectedbone_Y), max(detectedbone_Y)];
            window_extension      = 0.5 * 1e-6;
            window_safe           = window_critical + ([-1 1] * window_extension);
            
            % change the flag
            isPostprocess = true;
        end
    end

    % 4) Store everything if only the post processing is done
    if(isPostprocess)
        % convert time to distance
        detectedbone_Y_mm = (us_spec.v_sound * 1e3) * (0.5 * detectedbone_Y);
        windowsafe_mm     = (us_spec.v_sound * 1e3) * (0.5 * window_safe);

        all_bonepeak{current_probe} = [detectedbone_X', detectedbone_Y_mm];
        all_window(current_probe,:) = windowsafe_mm;

        %{
        % Getting the peak amplitude value 
        %
        % There is a problem here. We are too focus on locating the bone peak from
        % M-mode image space (it is easier since we have information from past and
        % future, hence Offline), until we forgot to obtain the amplitude
        % information from the bone peak.
        %
        % To be honest, peak amplitude is not as important as peak location. But we
        % might use it. For example: display purpose (peak on A-mode signal), or
        % giving weight for the next phase, Registration.
        %
        % This part we will focus on getting the information of the peak amplitude.
        % It is quite tricky, since we now have the 'continuous' function for depth
        % in the M-mode image space, that has denser resolution than the A-mode
        % signal itself (The period (T) of A-mode is 0.02 mus, and the 'location'
        % of the peak might be somewhere around that number). So we need to round
        % it first to the nearest 0.02, then we can search the amplitude trough
        % indexing from t_vector variable.
        
        % convert the unit to microsecond
        bone_mu_s         = detectedbone_Y * 1e6;
        % it is easier to operate at the order of 0.01 mus, since the resolution of
        % the A-mode (the periode, T) is within that order.
        bone_mu100_s      = bone_mu_s * 1e2;
        % rounding to the nearest multiple of two
        % https://nl.mathworks.com/matlabcentral/answers/272303-how-to-round-up-and-down-a-value-close-to-multiple-of-5#answer_212920
        bone_mu100round_s = 2*round(bone_mu100_s/2);
        % return back to microsecond
        bone_muround_s    = bone_mu100round_s * 1e-2;
        
        % search the value of bone_muround_s in t_vector and spit out the location
        % index in t_vector. Here, for bone_muround_s and t_vector, i put round() 
        % function again, just to make sure, sometimes they are not totally rounded 
        % after multiplication for unit adjustment, for ex: 11.2800000000001
        % https://nl.mathworks.com/matlabcentral/answers/32781-find-multiple-elements-in-an-array#answer_140551
        [~, loc_bonemuround_tvector] = ismember(round(bone_muround_s, 2), round(us_spec.t_vector, 2));

        % store the amplitude index, maybe will be use for display purposes
        all_ampidx{current_probe} = [detectedbone_X', loc_bonemuround_tvector'];
        %}
        amp_idx = knnsearch(us_spec.x_axis_values', detectedbone_Y_mm);
        all_ampidx{current_probe} = [detectedbone_X', amp_idx];

    else
        % put arbitrary number if there is no values.
        all_bonepeak{current_probe} = [];
        all_ampidx{current_probe}   = [];
        all_window(current_probe,:) = [2 5];
    end
    
    % storing the duration time for Peak Detection
    t_peak(current_probe) = toc;
    % --------------------------------------------------------------------------------------------------------

    
end

warning('on', 'signal:findpeaks:largeMinPeakHeight');

% put indicator to terminal
fprintf("Peak Detection is finished\n");
fprintf("average DSP/probe: %.4f s, overall DSP time: %.4f s \n", mean(t_dsp), sum(t_dsp));
fprintf("average PeakDetection/probe: %.4f s, overall PeakDetection time: %.4f s \n", mean(t_peak), sum(t_peak));
fprintf("overall DSP+PeakDetectionTime: %.4f s. \n", sum(t_dsp)+sum(t_peak));

% close the progress bar
close(f);

end

