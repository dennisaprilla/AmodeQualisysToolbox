function display_peak_all(display_order, probeNumber_toShow, envelope_clipped, data_spec, x_mm_clipped)
% This function is only used for displaying all the windowed m-mode with
% peaks at once. I usually use this function for report purpose.
% INPUT:
% display_order         a vector that will be used for arranging the display
% probeNumber_toShow    a numeric value, the start of the probes number in
%                       which we want tho show
% envelope_clipped      a clipped of envelop signal which came from the
%                       signal processing
% data_spec             a struct, specification about the dimension of our
%                       data
% x_mm_clipped          

addpath('../functions/displays/subaxis');

max_column = length(display_order);
max_row = max(display_order);

index_map = reshape(1:max_column*max_row, max_column, max_row)';
index_current = 1;

f = figure;
f.WindowState = 'maximized';
for j=1:max_column
    
    column_number = display_order(j);
    for i=1:column_number
        
        diff = max_row - column_number;
        
        current_axes = subaxis( max_row, max_column, index_map(index_current), ...
                                'SpacingVertical', 0.065, ...
                                'Padding', 0.0, ...
                                'Margin', 0.03);
                            
        display_mmode( current_axes, ...
                       probeNumber_toShow, ...
                       envelope_clipped, ...
                       data_spec, ...
                       x_mm_clipped);
        
        
        index_current = index_current+1;
        probeNumber_toShow = probeNumber_toShow+1;
    end
    
	index_current = index_current + diff;
    
    

end

