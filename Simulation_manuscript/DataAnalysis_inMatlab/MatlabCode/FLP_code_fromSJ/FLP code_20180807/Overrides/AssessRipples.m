function AssessRipples
global spc
global state

% First row displays Poisson noise (channel1 and channel 2)
% Second row displays stdev/mean as an assessment of magnitude of ripples
% modified by Suk Joon Lee 9/30/2016
for k=1:1;   
    %mean = variance in Poisson distribution
    lifetimes = double(spc.lifetimes{k});
    gy(1,k) =1/sqrt(mean(lifetimes(163:853))); %Possion noise's noise to signal ratio = noise standard deviation/mean = sqrt(mean)/mean
    gy(2,k) =std(lifetimes(163:853))/mean(lifetimes(163:853)); %relative standard deviation = std/mean
    gy(3,k) =sqrt(std(lifetimes(163:853))^2-sqrt(mean(lifetimes(163:853)))^2)/mean(lifetimes(163:853)); %unexplained std = sqrt(experimental variance - expected variance)/mean
    if(std(lifetimes(163:853))^2-sqrt(mean(lifetimes(163:853)))^2<0)
        gy(3,k)=0;
end; 

%display([num2str(gy(1,1)),' ',num2str(gy(2,1)),' ',num2str(gy(3,1)),' ',num2str(sum(spc.lifetimes{1}))]);

try
    load('rippledata.mat');
    temp=data;
    data=[temp;state.files.lastAcquisition,state.spc.acq.SPCdata{1}.sync_zc_level, state.spc.acq.SPCdata{1}.sync_threshold,gy(1,k),gy(2,k),gy(3,k), sum(spc.lifetimes{k})];
catch
    data=[state.files.lastAcquisition,state.spc.acq.SPCdata{1}.sync_zc_level, state.spc.acq.SPCdata{1}.sync_threshold,gy(1,k),gy(2,k),gy(3,k), sum(spc.lifetimes{k})];
end

save rippledata.mat data;
str = sprintf('%d %.2f %.2f %.4f %.4f %.4f %d', data( size(data,1),:) );
display('Acq# sync_zc sync_threshold Poisson_NSR RSD Ripple Photon_Count');
display(str);
end