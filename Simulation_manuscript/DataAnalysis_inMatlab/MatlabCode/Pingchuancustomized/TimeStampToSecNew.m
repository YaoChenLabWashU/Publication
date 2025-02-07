 % Get time (in sec from midnight) from Bonsai output of Timestamp information: '2019-07-18T11:19:13.9658752-05:00'
function out=TimeStampToSecNew(filename)
global TimeInSec Interval
fid=fopen(filename,'r'); %open the file
C=textscan(fid,'%s'); %read as strings
for i=1:length(C{1,1}) %go through every timestamp
    name=char(C{1,1}(i,1)); %Get the timestamp as string
    Time=name(80:95); % Get the time information
    Hour=str2double(Time(1:2));
    Min=str2double(Time(4:5));
    Sec=str2double(Time(7:end));
    TimeInSec(i,1)=Hour*3600+Min*60+Sec;
end

%Calculating intervals between neighboring stamped time
for i=1:(length(TimeInSec)-1)
    Interval(i,1)=TimeInSec(i+1,1)-TimeInSec(i,1);
end

%plot interval
figure;
plot(Interval);
end
