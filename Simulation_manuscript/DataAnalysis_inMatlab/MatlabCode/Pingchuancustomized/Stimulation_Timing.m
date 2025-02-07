% filename='ycAKAR052FLIM';
% 
% Time=xlsread(filename,'ES26:ES1000');
% Acq=xlsread(filename,'C26:C1000');

% filename2='ycAKAR052';
[~,text]=xlsread(filename2,'D26:D1000');
stim=strcmp(text,'PA_PKI_stim.cyc');
stimcycle=[];
j=1;
for i=1:size(cyclePos,1)
    if cyclePos(i)==2
        stimcycle(j)=i;
        j=j+1;
    end
end

stimcycle2=[];
j=1;
for i=1:size(stim,1)
    if stim(i)==1
        stimcycle2(j)=i;
        j=j+1;
    end
end

stimtime=[];

for i=1:size(stimcycle,2)
    stimtime(i)=Time(stimcycle(i)-3)
end



% 
% baselinec=mean(p1c1(1:23));
% baselinen=mean(p1n1(1:23));
% lftchangeC=[];
% lftchangeN=[];
% for i=size(stimcycle,1)-1
%     lftchangeC(i)=min(p1c1(stimcycle(i):stimcycle(i+1)));
%     lftchangeN(i)=min(p1n1(stimcycle(i):stimcycle(i+1)));
% end
% lftchangeC(i+1)=min(p1c1(stimcycle(i):end));
% lftchangeN(i+1)=min(p1n1(stimcycle(i):end));



% Epoch=xlsread(filename2,'C26:C1000');
% cyclePos=xlsread(filename2,'E26:E1000');
% Epochnum=[];
% j=1;
% for i=1:(size(Epoch)-1)
%     if Epoch(i+1)-Epoch(i)==1
%         Epochnum(j)=i+1;
%         j=j+1;
%     end
% end
% 
% Epochnum
% 
% cyclePosnum=[];
% j=1;
% for i=2:(size(cyclePos))
%     if cyclePos(i)-cyclePos(i-1)==1
%         cyclePosnum(j)=i;
%         j=j+1;
%     end
% end
% 
% cyclePosnum

% Timereal=[];
% for i=2:379
%     a=find(Time(:,2)==i);
%     if isempty(a)==0
%         Timereal(i-1)=Time(a,1);
%     end
% end
% 
% zerotimes=find(Timereal==0);
% 
% for i=2:size(zerotimes,2)
%     Timereal(zerotimes(i))=NaN;
% end
% 
% stimTime=[];
% for i=1:size(cyclePosnum,2)
%     a=find(Time(:,2)==cyclePosnum(i));
%     stimTime(i)=Time(a,1);
% end