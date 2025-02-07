
filename='0830AchsensorHCICI004FLIM_analysis_Pc_0914';
ROInum=6;
filenums=xlsread(filename,'C26:C1000');
lft=xlsread(filename,'G26:L1000');
intensity=xlsread(filename,'S26:X1000');
Time=xlsread(filename,'ES26:ES1000');
Acq=xlsread(filename,'C26:C1000');


% cycleposition=xlsread(filename,'FD26:FD1000');
% Photonnum=xlsread(filename,'S26:X1000')
% Timecounter=0;
% 
% 
% for i=1:ROInum
%     eval(['cell',num2str(i),'=zeros()'])
%     eval(['cell_intensity',num2str(i),'=zeros()'])
%     eval(['cell_time',num2str(i),'=zeros()'])
%     eval(['counter',num2str(i),'=1'])
% end
% 
% 
% 
% for i=1:size(cycleposition,1)
%     Timecounter=Timecounter+1;
%     for j=1:ROInum
%         if isnan(lft(i,j))==0
%             eval(['cell',num2str(j),'(counter',num2str(j),')','=lft(',num2str(i),',',num2str(j),')'])
%             eval(['cell_intensity',num2str(j),'(counter',num2str(j),')','=intensity(',num2str(i),',',num2str(j),')'])
%             eval(['cell_time',num2str(j),'(counter',num2str(j),')','=Time(Timecounter)'])
%             eval(['counter',num2str(j),'=counter',num2str(j),'+1'])
%         end
%     end
%             
% end
%         