function InsertDroppedFrames(video_file, timestamp_file)
%This function checks for neighboring timestamps with long gaps, if there are long gaps it repeats the current frame to fill in the "missing frames"
% insertText requires the Computer Vision toolbox.
% timestamp_file assumes no "false" or "true" column.
% Make sure you check the frame rate read off the video (line 20) and
% compare the figure of time intervals plotted based on the timestamp (line 39). They
% should be fairly similar.



%%
insert_ts = true; % insert timestamps?

%%
[fpath, fname, fext] = fileparts(video_file);
new_video_file = fullfile(fpath, sprintf('%s_filled.mp4', fname));
%%
%%Read video and figure out framerate
v = VideoReader(video_file);
fps=v.FrameRate %frame rate, also displayed in Matlab

%% first read in the timestamps

str = fileread(timestamp_file);
str = regexp(str, '\n', 'split');
str = str(1:end-1);
str = strtrim(str);

%% convert to datetimes

period = 1 / fps;
divisor = round(period * 1e2) / 1e2; % round to 10ms

dts = datetime(str, 'InputFormat','yyyy-MM-dd''T''HH:mm:ss.SXXXXXX', 'TimeZone','America/Chicago');
nframes = length(dts);
dts_diff = seconds(diff(dts));
dts_diff_p1=[0];
dts_diff=[dts_diff_p1 dts_diff];
figure; plot(dts_diff); % plotting the time interval

% assume if neighboring frames are separated by >1 period you need to
% insert data

mframes = floor(seconds(diff([dts(:);dts(end)])) / divisor);

mframes = max(mframes, 1); % this vector = 1 if no missing frames > 1 for missing frames
mframes_loc = find(mframes > 1); % locations with missing frames

%%
v = VideoReader(video_file);
% if ispc
vout = VideoWriter(new_video_file, 'MPEG-4'); %compressed version in mp4 format
vout.FrameRate = fps; 
open(vout);

h = waitbar(0,'Writing video...');
ts = 0;

for i=1:nframes
    disp([i]);
    waitbar(i / nframes)
    frame = readFrame(v);
    ts = ts + dts_diff(i);
    for j=1:mframes(i) % repeat the frame MFRAMES(i) times to fill in for missing frames
        if insert_ts
            ts_str = datestr(seconds(ts), 'HH:MM:SS.FFF');
            frame = insertText(frame, [50 75], ts_str);                      % set timebar to each frame
            frame = insertText(frame, [50 50], str(i));                      % set datetime to each frame
            frame = insertText(frame, [50 100], i);                          % Kusch added on 3/10/2021, to set the frame number in to each frame
        end
        writeVideo(vout, frame);
    end
end
% elseif isunix
%     vout = VideoWriter(new_video_file, 'Uncompressed AVI');
%     vout.FrameRate = fps;
%     open(vout);
%
%     h = waitbar(0,'Writing video...');
%     ts = 0;
%
%     for i=1:nframes
%         %disp([i]);
%         waitbar(i / nframes)
%         frame = readFrame(v);
%         ts = ts + dts_diff(i);
%         for j=1:mframes(i) % repeat the frame MFRAMES(i) times to fill in for missing frames
%             if insert_ts
%                 ts_str = datestr(seconds(ts), 'HH:MM:SS.FFF');
%                 frame = insertText(frame, [50 75], ts_str);                      % set timebar to each frame
%                 frame = insertText(frame, [50 50], str(i));                      % set datetime to each frame
%             end
%             writeVideo(vout, frame);
%         end
%     end
%     pathVideomp4=regexprep('\.avi','.mp4'); generate mp4 filename
%     [~,~] = system(sprintf('ffmpeg -i %s -y -an -c:v libx264 -crf 0 -preset slow %s')); % for this to work, you should have installed ffmpeg and have it available on PATH
% end

close(vout);
close(h);
%%

% v = VideoReader(new_video_file);
end