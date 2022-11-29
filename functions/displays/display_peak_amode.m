function display_peak_amode(current_axes, allpeaks, probeNumber_toShow, timestamp_toShow, tag)

delete(findobj('Tag', tag));

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
    current_peaks = allpeaks.locations(probeNumber_toShow, timestamp_toShow);
    xline(current_axes, current_peaks, '-', 'Color', 'b',  'Tag', tag);
end

end

