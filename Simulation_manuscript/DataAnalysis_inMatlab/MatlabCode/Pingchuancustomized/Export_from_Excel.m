


filename='1029PAPKIHEKcell003FLIM';
ROInum=6;
filenums=xlsread(filename,'C26:C1000');
lft=xlsread(filename,'G26:L1000');
intensity=xlsread(filename,'S26:X1000');
Time=xlsread(filename,'ES26:ES1000');
Acq=xlsread(filename,'C26:C1000');

intensity(intensity==0)=NaN;
intensity_ratio=intensity;
intensity_max=[];


filename2='1029PAPKIHEKcell003';
Epoch=xlsread(filename2,'C26:C1000');
cyclePos=xlsread(filename2,'E26:E1000');
Epochstartnum=[];
j=1;
for i=1:(size(Epoch)-1)
    if Epoch(i+1)-Epoch(i)==1
        Epochstartnum(j)=i+1;
        j=j+1;
    end
end

Epochstartnum


Epochstarttime=[];
for i=2:size(Epochstartnum,2)
    a=find(Acq==Epochstartnum(i));
    Epochstarttime(i)=Time(a);
end

Epochstarttime

for i=1:size(intensity,2)
    intensity_ratio(:,i)=intensity_ratio(:,i)/nanmean(intensity(1:(Epochstartnum(2)-Acq(1)),i));
end

for i=1:size(intensity,2)
    intensity_max(i)=max(intensity_ratio(:,i));
end

baselinechange=[];
for i=1:size(intensity,2)
    baselinechange(i)=max(intensity_ratio(1:Epochstartnum(2)-Acq(1),i))
end