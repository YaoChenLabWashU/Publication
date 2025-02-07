% This function is used to extract the time information from intensity
% based imaging dataset.
function AcqTime = TimeFromAcq(TotalAcq)

AcqTime=zeros(TotalAcq,1);


for i=1:TotalAcq
    CurVar=['c1r1_',num2str(i),'.mat'];
    eval(['exist ','c1r1_',num2str(i),'.mat',' file']);
    ExistOrNot=ans;
    if ExistOrNot == 2;
       load(CurVar);
       eval(['CurTime=c1r1_',num2str(i),'.timeStamp']);
       AcqTime(i)=CurTime;
    end
end

AcqTime=AcqTime-AcqTime(7);

save AcqTime AcqTime

    
