filename='HekAchSensor04ug001';
Epoch=xlsread(filename,'C26:C1000');
Epochnum=[];
j=1;
for i=1:(size(Epoch)-1)
    if Epoch(i+1)-Epoch(i)==1
        Epochnum(j)=i+1;
        j=j+1;
    end
end


Epochnum
baselinetime=Time(Epochnum(2));
baselinetimes=[];
baselinelft=[];
baselineintensity=[];
for i=1:6
    for j=1:size(cell1,2)
        eval(['a=cell_time',num2str(i),'(',num2str(j),')-baselinetime']);
        if a>0
           baselinetimes(i)=j; 
           eval(['baselinelft(',num2str(i),')=mean(cell',num2str(i),'(1:j))'])
           eval(['baselineintensity(',num2str(i),')=mean(cell_intensity',num2str(i),'(1:j))'])
            break
        end
    end
end


