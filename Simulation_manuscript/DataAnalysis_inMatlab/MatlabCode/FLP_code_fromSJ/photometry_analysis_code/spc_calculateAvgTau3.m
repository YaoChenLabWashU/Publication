function avgTau = spc_calculateAvgTau3(ch)
%% calculating approximated avg tau using the weighted sum of arrival time
% automatic detection of the baseline using the lowest 5% across 1ns-17.5ns
% range

global spc

%to = find(spc.fits{ch}.prf==max(spc.fits{ch}.prf)) * spc.datainfo.psPerUnit/1000;
%to = -spc.fits{ch}.beta5+ find(spc.fits{ch}.prf==max(spc.fits{ch}.prf)) * spc.datainfo.psPerUnit/1000;
to = spc.fits{ch}.beta5+spc.fits{ch}.fitstart; %end datapoints to fit

nsPerPoint=spc.datainfo.psPerUnit/1000;
range = round([spc.fits{ch}.fitstart spc.fits{ch}.fitend]/nsPerPoint);
range(1) = round(to/nsPerPoint);

lifetimes=spc.lifetimes{ch}(range(1):range(2));
%lifetimes=spc.lifetimes{ch}(range(1):range(2));
%lifetimes = spc.lifetimes{ch};

%baseline subtraction
baseline=cal_baseline(ch); %update baseline for each time point
%baseline=mean(spc.lifetimes{ch}(650:700)); %update baseline for each time point
lifetimes=lifetimes-baseline;

sum1=0;
for j=1:length(lifetimes)
    if(lifetimes(j)>0)
        sum1 = sum1 + ((range(1)-1+j)*spc.datainfo.psPerUnit/1000)*lifetimes(j);
    end
end
sum2=sum(lifetimes);

if(sum2>0)
    avgTau = sum1/sum2- to;
else
    avgTau =0;
end

%display(to);

%% using approximated avgtau with double exponential fit
% spc_fitexp2gaussGY(ch);
% avgTau = spc.fits{ch}.avgTau;
end