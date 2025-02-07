
% timestamp_file=['0408AchsensorHPC004',num2str(i),'.txt']; % define name the text file of timestamp for insert dropped frames function
timestamp_file=['/scratch/pcma/Video/0427AchsensorEEGEMG001/0427AchsensorEEGEMG001',num2str(i),'.csv'];    
video_file=['/scratch/pcma/Video/0427AchsensorEEGEMG001/0427AchsensorEEGEMG001',num2str(i),'.avi']; % video file name to read
interval_file=['/scratch/pcma/Video/0427AchsensorEEGEMG001/0427AchsensorEEGEMG001',num2str(i)];
fps_read=['/scratch/pcma/Video/0427AchsensorEEGEMG001/0427AchsensorEEGEMG001',num2str(i),'.mat'];
% excel_file=['0408AchsensorHPC004',num2str(i),'.csv']; % excel file of the timestamp
%     [num,txt,raw]=xlsread(excel_file); % read the excel file
%     fid=fopen(timestamp_file,'wt');
%     fprintf(fid,'%s\n',raw{:});
%     fclose(fid); % save the excel as txt
    InsertDroppedFrames_FromYao(video_file, timestamp_file, interval_file, fps_read);
