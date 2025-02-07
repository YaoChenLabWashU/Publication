function avgTau = spc_calculateAvgTau_downsample(ch,bin)
global spc

%% calculating approximated avttau using the weighted sum of arrival time
%to = find(spc.fits{ch}.prf==max(spc.fits{ch}.prf)) * spc.datainfo.psPerUnit/1000;
%to = -spc.fits{ch}.beta5+ find(spc.fits{ch}.prf==max(spc.fits{ch}.prf)) * spc.datainfo.psPerUnit/1000;
to = spc.fits{ch}.beta5+spc.fits{ch}.fitstart;

nsPerPoint=spc.datainfo.psPerUnit/1000;
range = round([spc.fits{ch}.fitstart spc.fits{ch}.fitend]/nsPerPoint);
range(1) = round(to/nsPerPoint);

lifetimes=spc.lifetimes{ch}(range(1):range(2));

%baseline subtraction
lifetimes=lifetimes-mean(spc.lifetimes{ch}(100:150)); 

temp=[];
for i=1:floor(length(lifetimes)/bin)
    temp(i)=sum(lifetimes((i-1)*bin+1:i*bin));
end
lifetimes=temp;

sum1=0;
for j=1:length(lifetimes)
    sum1 = sum1 + ((range(1)-1+j*bin)*spc.datainfo.psPerUnit/1000)*lifetimes(j);
end
sum2=sum(lifetimes);

if(sum2>0 && sum1>0)
    avgTau = sum1/sum2- to;
else
    avgTau =0;
end

%display(to);

%% using approximated avgtau with double exponential fit
% spc_fitexp2gaussGY(ch);
% avgTau = spc.fits{ch}.avgTau;
end