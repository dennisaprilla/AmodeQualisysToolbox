function gui_setSlider(slider_handle, min, max, value, small_step, big_step)

set(slider_handle, 'Min', min);
set(slider_handle, 'Max', max);
set(slider_handle, 'Value', value);

slider_range = max - min;
steps = [small_step/slider_range, big_step/slider_range];
set(slider_handle, 'SliderStep', steps);

end

