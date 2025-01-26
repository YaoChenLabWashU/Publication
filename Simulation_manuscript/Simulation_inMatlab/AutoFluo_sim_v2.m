function [n_auto] = AutoFluo_sim_v2(autofluo, AF)

% AutoFluo_sim_v2 simulate samples with a known empirical distribution. For example, the
% distribution could be an empirically collected autofluorescence
% distribution or even distribution of background.

xsim = (0:1:255)*(12.5/256); % define the 256 time channels
 
Autofluorescence=zeros(1, AF); % Give each photon zero lifetime to start with.
for i=1:AF
    Autofluorescence(i)=find(histc(rand(),[cumsum(autofluo(:))]))*(12.5/256); % Draw a lifetime for autofluorescence based on the probability specified in the measured autofluorescence file.
end


[n_auto, xout]=hist(Autofluorescence, xsim); % Based on the photons and their lifetime, generate the simulated 256-channel histogram.

end

