function [all_ultrasoundfrd, timestamps, indexes] = readTIFF_USsignal(directory, n_probes, n_samples)
% DESCRIPTION:
% Function to read ultrasound data which stored as a TIFF image file.
% INPUT:
% directory         Path where the tiff images are stored. you either can
%                   use sparator ('\') at the end or not
% n_probes          Number of probes that is used by the ultrasound
%                   machine. Usually we use 30 probes
% n_samples         How many data sample per probes. By default the
%                   ultrasound machine send 1500 samples per probes.
% OUTPUT:
% all_ultrasoundfrd An (n_probes, n_samples, n_files) matrix containing
%                   ultrasound signal.
% timestamps        An vector of timestamp. Each of the data is correspond
%                   to the third dimension of all_ultrasoundfrd matrix
% indexes           Only used for debugging only. It shows the data number
%                   that is sent from Ultrasound machine. Sometimes it
%                   skipped number, telling us there is some data that is
%                   corrupted. Each of the data is corresponds to the third
%                   dimension of all_ultrasoundfrd matrix,

% array to store the timestamps and index
timestamps = [];
indexes = [];

% specify where is the folder
if ( ~strcmp(directory(end), '\') )
    directory = strcat(directory, '\');
end
filenames = dir(strcat(directory, '*.tiff'));

% allocating some space here
n_files = size(filenames, 1);
all_ultrasoundfrd = zeros(n_probes, n_samples, n_files);

% put indicator to terminal
disp("Reading the data, please wait ...");
% show the progress bar, so that the user is not bored
f = waitbar(0, sprintf('%d/%d Frame', 0, n_files), 'Name', 'Loading TIFF image');

% loop for all ever the tiff image
for file=1:n_files
    
    % display progress bar
    if (mod(file,25)==0)
        waitbar( file/n_files, f, sprintf('%d/%d Frame', file, n_files) );
    end
    
    % get the timestamp from the file name
    strings = split(filenames(file).name, "_");
    timestamp = str2double(strings{1});
    % get the image index number (if we specify index for data retreival)
    strings = split(strings{2}, ".");
    index = str2num(strings{1});
    % save it to array for some reason
    timestamps = [timestamps; timestamp];
    indexes = [indexes; index];
    
    % read the tiff file
    tiff_image = read(Tiff(strcat(filenames(file).folder, '\', filenames(file).name)));
    
    % loop for each if the image
    for probe=1:n_probes
        % convert it to int16 and store it to a huge matrix
        all_ultrasoundfrd(probe, :, file) = typecast(tiff_image(probe,:), 'int16');
    end
    
end

% show the information about the variable
all_ultrasoundfrd_info = whos('all_ultrasoundfrd');
fprintf("Reading finished. Variable size: %.2f MB\n", all_ultrasoundfrd_info.bytes/(1024*1024));

% close the progress bar
close(f);

end

