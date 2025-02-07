function [ Epochnum ] = Epochnumbers( filename2 )
%
%   
Epoch=xlsread(filename2,'C26:C1000');
cyclePos=xlsread(filename2,'E26:E1000');
Epochnum=[];
j=1;
for i=1:(size(Epoch)-1)
    if Epoch(i+1)-Epoch(i)==1
        Epochnum(j)=i+1;
        j=j+1;
    end
end



end

