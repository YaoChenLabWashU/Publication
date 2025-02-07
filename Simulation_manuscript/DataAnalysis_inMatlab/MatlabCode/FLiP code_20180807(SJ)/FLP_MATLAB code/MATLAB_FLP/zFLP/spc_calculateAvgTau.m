function avgTau = spc_calculateAvgTau(ch)
global spc

nsPerPoint=spc.datainfo.psPerUnit/1000;
range = round([spc.fits{ch}.fitstart spc.fits{ch}.fitend]/nsPerPoint);

%to = find(spc.fits{ch}.prf==max(spc.fits{ch}.prf)) * spc.datainfo.psPerUnit/1000;
%to = -spc.fits{ch}.beta5+ find(spc.fits{ch}.prf==max(spc.fits{ch}.prf)) * spc.datainfo.psPerUnit/1000;
to = spc.fits{ch}.beta5+spc.fits{ch}.fitstart;
%range(1)=round(to/nsPerPoint);

%lifetimes=spc.lifetimes{ch}(range(1):range(2))-mean(spc.lifetimes{1}(200:400)); %subtract baseline before avg lifetime calculation
lifetimes=spc.lifetimes{ch}(range(1):range(2));
%lifetimes = spc.lifetimes{ch};

sum1=0;
for j=1:length(lifetimes)
    sum1 = sum1 + ((range(1)-1+j)*spc.datainfo.psPerUnit/1000)*lifetimes(j);
end
sum2=sum(lifetimes);

if(sum2>0)
    avgTau = sum1/sum2- to;
else
    avgTau =0;
end

end