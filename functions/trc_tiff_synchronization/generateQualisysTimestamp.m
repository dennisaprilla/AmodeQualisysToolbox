function generated_timestamps = generateQualisysTimestamp(qualisys_struct)

timestamps_start = 0;
timestamps_step  = 1/qualisys_struct.FrameRate;
timestamps_end   = timestamps_step*(qualisys_struct.Frames-1);

generated_timestamps = (timestamps_start:timestamps_step:timestamps_end)';

end

