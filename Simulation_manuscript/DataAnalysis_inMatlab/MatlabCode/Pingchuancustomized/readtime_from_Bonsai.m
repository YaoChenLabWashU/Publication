
timestamp_file='20220208_109_AChMut_RvR_001_timestamp0.csv';

speed_file='20220208_109_AChMut_RvR_001_speed_only.csv';

str=readtable(timestamp_file,'ReadVariableNames',false,'Delimiter',' ');
str=table2cell(str);
dts=datetime(str,'InputFormat','yyyy-MM-dd''T''HH:mm:ss.SXXXXXX','TimeZone','America/Chicago');
dts_norm=dts-dts(1);
time_from_bonsai=seconds(dts_norm);


speed=readtable(speed_file,'ReadVariableNames',true);
speed=table2array(speed);
speed(end)=[];


