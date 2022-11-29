function gui_toggleElement(handles, string_switch)

set(handles.popup_probenumber, 'Enable', string_switch);

set(handles.edit_windowlowerbound,'Enable', string_switch);
set(handles.slider_windowlowerbound,'Enable', string_switch);

set(handles.edit_windowupperbound,'Enable', string_switch);
set(handles.slider_windowupperbound,'Enable', string_switch);

set(handles.slider_timestamp,'Enable', string_switch);
set(handles.edit_timestamp,'Enable', string_switch);
set(handles.button_play, 'Enable', string_switch);
set(handles.button_pause, 'Enable', string_switch);

set(handles.button_export, 'Enable', string_switch);
set(handles.button_detectdepth, 'Enable', string_switch);

set(handles.edit_pathwindowconf, 'Enable', string_switch);
set(handles.button_openwindowconf, 'Enable', string_switch);

end

