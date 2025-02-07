function y = spc_exp2prfGY(par, x)
global spc;

TAC_offset_shift = 19;
% this function is used for calculating the fit:
%  double exponential + empirical PRF

% kept older usage even in multiFLIM (this is how we pass params)
range = spc.fit.range;
% new background correction plan gy 20120717
% the setup program calls spc_calcBackgrd to set up
%   spc.fit.backVal and spc.fit.backRange
% here we calculate the "tail" value in backRange
%  and then ADD to the full fit a constant 
%  backVal - tail(backRange)
%
% background = mean(spc.lifetime(range(1):range(1)+10));
%background = 0;
%backprf = mean(spc.fit.prf(range(1):range(1)+10));

amp1 = par(1);
tau1 = par(2); 
amp2 = par(3);
tau2 = par(4); 
deltapeak = par(5);
scatter = par(6);  % introduced gy 20120720 as SHG term
% for debugging:
% disp(['spc_exp2prfGY ' num2str(amp1) ' ' num2str(tau1) ' ' num2str(amp2) ' ' num2str(tau2) ' ' num2str(deltapeak) ' ' num2str(scatter)]);

% if scatter<0  % put a clumsy limit on this to prevent negative vals
%     scatter=0;
% end
if spc.datainfo.pulseInt==inf
    spc.datainfo.pulseInt=12.5
end

pulse_int = round(spc.datainfo.pulseInt*1000/spc.datainfo.psPerUnit);
pulse_int = 256; % Pingchuan 2023.05.04
% disp('TAC_offset_shift = 19, PulseInt = 20, 256 channels')
prf1 = spc.fit.prf(range(1):range(2));
prf = interp1(x, prf1, x+deltapeak, 'linear');
prf(isnan(prf)) = 0;

lenx = length(x);
%x = (1:lenx+pulse_int);  % shouldn't x start at 0 ?!  changed gy 20120720
x = (0:lenx-1+pulse_int);  % gy 20120720
x = x(:);

% beta0(1) = abs(beta0(1));
% beta0(3) = abs(beta0(3));

lifetime = amp1*exp(-x/tau1)+amp2*exp(-x/tau2);
lifetime(1)=lifetime(1)+scatter;  % add this delta func at t=0 for SHG  gy 20120720
y1 = conv(lifetime, prf); % length: lenx + pulse_int + 256 - 1

y2 (1:lenx) = y1 (pulse_int+1:pulse_int+lenx);
% y2 = zeros(lenx+TAC_offset_shift, 1);
% y2 (TAC_offset_shift:lenx+TAC_offset_shift) = y1 (pulse_int+TAC_offset_shift:pulse_int+TAC_offset_shift+lenx); % modified by Pingchuan, 2023.06.14, 
y1 = y1(1:lenx);


y = y1(:) + y2(:);

% correct for BACKGROUND gy 20120718
y=spc_addBackgroundToFit(y);

% add a punishment for negative values of SHG gy 20130510
[~,locmin]=min(y);
if scatter<0
    y(1:locmin)=y(1:locmin)-10*exp(-scatter);
end
