function [prf] = SavePRF(FilePath, PrfName, range1_ratio, range2_ratio, ZeroChannels_ratio, Ch)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
global spc

range1 = floor(range1_ratio*length(spc.lifetimes{Ch}));
range2 = floor(range2_ratio*length(spc.lifetimes{Ch}));
ZeroChannels = floor(ZeroChannels_ratio * length(spc.lifetimes{Ch}));

prf = spc.lifetimes{Ch};
baseline = mean(prf(range1:range2));
disp(['Baseline of ' num2str(baseline) ' subtracted...']);
disp(['Baseline from channel ' num2str(range1) ' to channel ' num2str(range2)]);
disp(['Channels after ' num2str(ZeroChannels) ' are 0']);

prf=prf-baseline;
% zero out the last 10%
prf(ZeroChannels:end)=0;
% make sure there are no negative numbers
prf(prf<0)=0;
% normalize to unit area
prf=prf/sum(prf);
% use this prf for current fits
spc.fits{spc_mainChannelChoice}.prf=prf;
% and save in a file
save ([FilePath, PrfName], 'prf');

end