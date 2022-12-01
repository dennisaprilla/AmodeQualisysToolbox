function display_peak_amode(current_axes, allpeaks, display_mode, probeNumber_toShow, timestamp_toShow, tag)

delete(findobj(current_axes, 'Tag', tag));

% If the current_peaks variable is a cell, it means the user wants to run a full
% ultrasound signal processing without any windowing. The peak could be
% more than one and it the number is varies for each probes for each time
% frame, thus cell data-type is the best alternative to store it.
if (iscell(allpeaks.locations))
    
   current_peaks = allpeaks.locations{probeNumber_toShow, timestamp_toShow};
   for i=1:length(current_peaks)
        xline(current_axes, current_peaks(i), '-', sprintf('#%d', i), 'Color', 'b',  'Tag', tag);
   end
    
% if the current_peaks is just one number, it means the user run an ultrasound 
% signal processing with windowing.
else

    % % display peak with line
    % current_peaks = allpeaks.locations(probeNumber_toShow, timestamp_toShow);
    % xline(current_axes, current_peaks, '-', 'Color', '#EDB120', 'LineWidth', 1.5, 'Tag', tag);

    if (strcmp(display_mode, 'distance'))
        current_peak = allpeaks.locations(probeNumber_toShow, timestamp_toShow);
    elseif (strcmp(display_mode, 'time'))
        current_peak = allpeaks.times(probeNumber_toShow, timestamp_toShow);
    else
        warning("Can not recognice the display mode for A-mode, specified as 'location' (found in display_peak_amode)");
        current_peak = allpeaks.locations(probeNumber_toShow, timestamp_toShow);
    end

    % display peak with point
    current_peaks_sharpness = allpeaks.sharpness(probeNumber_toShow, timestamp_toShow);
    hold(current_axes, 'on');
    plot(current_axes, current_peak, current_peaks_sharpness, 'or',  'MarkerFaceColor', 'y', 'MarkerSize', 10, 'LineWidth', 2, 'Tag', tag );
    hold(current_axes, 'off');
    
end

end

