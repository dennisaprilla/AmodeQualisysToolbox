function display_usabledata_mmode(current_axes, n_frames, x_axis_values, usable_timestamp, tag)

    delete(findobj(current_axes, 'Tag', tag));
    
    patch1_x = [ 1,                usable_timestamp(1), usable_timestamp(1),  1                  ];
    patch1_y = [ x_axis_values(1), x_axis_values(1),    x_axis_values(end),   x_axis_values(end) ];
    
    patch2_x = [ usable_timestamp(2), n_frames,         n_frames,           usable_timestamp(2) ];
    patch2_y = [ x_axis_values(1),    x_axis_values(1), x_axis_values(end), x_axis_values(end)  ];
    
    patch(current_axes, patch1_x, patch1_y, 'black', 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'Tag', tag);
    patch(current_axes, patch2_x, patch2_y, 'black', 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'Tag', tag);

end

