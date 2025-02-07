function peak_channels = FindPeakChannels(lifetime_histograms)
% This function is to find and output the peak channels of a bundle of
% lifetime_hitograms.
peak_channels=[];

for i=1:size(lifetime_histograms, 2)
    peak_channel_single=mean(find(lifetime_histograms(:,i)==max(lifetime_histograms(:,i))));
    peak_channels=[peak_channels peak_channel_single];
end

end