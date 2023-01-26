function [peak_idx_softtissues, peak_idx_bone, peak_idx_echo] = eliminatePeakEcho(peaks, locs, echo_ratio, echo_range)
% SUMMARY: When we want to detect bone peak, the measurement can also be
% affected by ultrasound echo. This function is intended to eliminate the
% echo. We assume, the echo is a product of a very high peak in the middle
% way between the beginining of the signal and the echo.

% variable to collect the possible echoes
peak_idx_echo = [];
peak_idx_bone = [];
peak_idx_softtissues = [];

% loop from the end peaks to the begining
for current_peak = length(locs):-1:2
    % get all peak magnitude except the current (investigated) one
    candidate_origin = peaks(1:current_peak-1);
    % echo will never higher than the origin, only picks the higher one
    % this echo_ratio is actually can be modelled based on
    % ultrasound attenuation inside the softtissue
    possible_origin_1  = find( echo_ratio .* candidate_origin > peaks(current_peak));

    % make the range of possible echo source
    range_origin = locs(current_peak)/2 + [-echo_range echo_range]*1e-6;
    % get all the peak location except the current (investigated) one
    candidate_origin = locs(1:current_peak-1);
    % find peak location which falls within range
    possible_origin_2 = find(candidate_origin>range_origin(1) & candidate_origin<range_origin(2));

    % combine the two requirement
    possible_origin=intersect(possible_origin_1, possible_origin_2);

    % if not empty, let's collect it (we assume only one fall
    % within this range, as we specified MinPeakDistance in findpeak)
    if(~isempty(possible_origin))
        peak_idx_echo = [peak_idx_echo, current_peak];
    end
end

% select the non-echoes
peak_idx_notecho     = find(~ismember(1:length(locs), peak_idx_echo));

if(~isempty(peak_idx_notecho))
    peak_idx_bone        = peak_idx_notecho(end);
    peak_idx_softtissues = peak_idx_notecho(1:end-1);
end

end

