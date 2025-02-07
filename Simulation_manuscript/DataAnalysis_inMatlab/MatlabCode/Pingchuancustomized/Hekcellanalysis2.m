filename2='1127mAKARIUE003';
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

% cyclePosnum=[];
% j=1;
% for i=2:(size(cyclePos))
%     if cyclePos(i)-cyclePos(i-1)==1
%         cyclePosnum(j)=i;
%         j=j+1;
%     end
% end
% cyclePosnum
% 
% Epochtimes=[]
% for i=1:size(Epochnum,2)
%     Epochtimes(i)=Time(Epochnum(i));
% end
% Epochtimes
%     
% baselinetime=Time(Epochnum(2));
% baselinetimes=[];
% baselinelft=[];
% baselineintensity=[];
% for i=1:ROInum
%     for j=1:size(cell1,2)
%         eval(['a=cell_time',num2str(i),'(',num2str(j),')-baselinetime'])
%         if a>0
%            baselinetimes(i)=j; 
%            eval(['baselinelft(',num2str(i),')=mean(cell',num2str(i),'(1:j))'])
%            eval(['baselineintensity(',num2str(i),')=mean(cell_intensity',num2str(i),'(1:j))'])
%             break
%         end
%     end
% end
% 
% 
% for i=1:ROInum
%     eval(['cell',num2str(i),'s=smooth(cell',num2str(i),')']);
%     eval(['cell_intensity',num2str(i),'s=smooth(cell_intensity',num2str(i),')']);
% end
% 
% for i=1:ROInum
%     eval(['cell',num2str(i),'r=(cell',num2str(i),'s','-baselinelft(',num2str(i),')',')/(max(cell',num2str(i),'s',')-baselinelft(',num2str(i),')',')']);
%     eval(['cell_intensity',num2str(i),'r=(cell_intensity',num2str(i),'s','-baselineintensity(',num2str(i),')',')/(max(cell_intensity',num2str(i),'s',')-baselineintensity(',num2str(i),')',')']);
% end
% 
% countermin=10000;
% for i=1:ROInum
%     eval(['countermin=min(counter',num2str(i),',countermin)'])
% end
% 
% for i=1:ROInum
%     eval(['diff=counter',num2str(i),'-countermin'])
%     if diff>0
%         for j=1:diff
%         eval(['cell',num2str(i),'r(:,end)=[];'])
%         eval(['cell_intensity',num2str(i),'r(:,end)=[];'])
%         end
%     end
% end
% 
% cellr=[];
% cell_intensity_r=[];
% for i=1:ROInum
%     eval(['cellr=[cellr;cell',num2str(i),'r]']);
%     eval(['cell_intensity_r=[cell_intensity_r;cell_intensity',num2str(i),'r]']);
% end
