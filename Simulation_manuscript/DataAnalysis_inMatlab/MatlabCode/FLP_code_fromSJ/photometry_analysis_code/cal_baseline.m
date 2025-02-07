function baseline = cal_baseline(ch)
%% calculating the baseline value (mean of lowest 5% values in lifetime hitogram)
% automatic detection of the baseline using the lowest 5% across 1ns-17.5ns
% range

global spc

%to = find(spc.fits{ch}.prf==max(spc.fits{ch}.prf)) * spc.datainfo.psPerUnit/1000;
%to = -spc.fits{ch}.beta5+ find(spc.fits{ch}.prf==max(spc.fits{ch}.prf)) * spc.datainfo.psPerUnit/1000;
%to = spc.fits{ch}.beta5+spc.fits{ch}.fitstart;

nsPerPoint=spc.datainfo.psPerUnit/1000;
range = round([1 17.5]/nsPerPoint);

%range(1) = round(to/nsPerPoint);

lifetimes=spc.lifetimes{ch}(range(1):range(2));

temp=sort(lifetimes);
idx=round(length(lifetimes)*0.05); %lowest 5%
baseline=mean(temp(1:idx));
end