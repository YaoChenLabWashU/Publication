for i=21:23
    timestamp_file=['0407AchsensorHPC003',num2str(i),'.txt'];
    video_file=['0407AchsensorHPC003',num2str(i),'.avi'];
    excel_file=['0407AchsensorHPC003',num2str(i),'.csv'];
    [num,txt,raw]=xlsread(excel_file);
    fid=fopen(timestamp_file,'wt');
    fprintf(fid,'%s\n',raw{:});
    fclose(fid);
    InsertDroppedFrames2(video_file, timestamp_file);
end