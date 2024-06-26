function [n1,n2, n] = FLIMsim512_v3(CycleLength, SS, PrfName, PopulationName)

%   FLIMsim512_FLIM_v2 performs:
%   1. draws samples from a population of idealized lifetime
%   distribution. The distribution comes from the population generated
%   from function GenPop_512_FLIM_v2
%   2. convolves the sample drawn with PRF

%   SS: sample size
%   PrfName: saved prf file for convoluting the population
%   PopulationName: the idealized lifetime distribution saved


%   Section 1: draw samples from the idealized population with replacement
load(PopulationName); % load the idealized lifetime distribution saved from function GenPop_512_FLIM_v2

Sample=Population(randi(length(Population), 1, SS)); % each number in the vector Sample represent one photon with that arrival time

%   Section 2: for each sample, convert it to a different lifetime based on
%   the prf lifetime distribution.
load(PrfName); % Load saved prf
SampleC=zeros(1, length(Sample)); % New vector for the photons with new lifetime after convolution
for i=1:length(Sample)
    b=rand();
    a=find(histc(b,[0;cumsum(prf(:))]))-1; % Determine the shift of the lifetime of the photon based on the probability of the prf distribution

    SampleC(i)=Sample(i)+a*(CycleLength/256); % Adjust the lifetime of the photon

end

% Section 3: Now turn the samples into histogram counts and do wrap-around
% to generate a 256-channel histogram

xsim2=(0:1:767)*(CycleLength/256); % The lifetime channels after covolution. A 512-element vector convoluted by a 256-element prf now becomes a 767-element vector

[n1, xout1]=hist(Sample, xsim2); % n1 is the histogram before convolution
[n2, xout2]=hist(SampleC, xsim2); % n2 is the histogram after convolution

% For n2, wrap around the tail after 256 channels to generated the final
% sensor histogram with 256 channels
n3=n2(257:512);
n=n2(1:256)+n3; % n is the final 256-channel histogram

end

