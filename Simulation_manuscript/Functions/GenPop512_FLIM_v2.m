function [] = GenPop512_FLIM_v2(TP, p1, p2, tau1, tau2, PopulationName)

%   This is a function to generate a population of lifetimes based on a double exponential exponential fit.  
%   TP=total number of photons at max in the histogram
%   p1 = fraction of population 1
%   p2 = fraction of population 2
%   tau1=lifetime 1
%   tau2=lifetime 2
%   PopulationName: Name the population generated

% 2023.11.29: found the issue with defining the x axis
% (xsim=linspace(0,25,512);); previous way make the channel width not
% exactly 12.5/256; changed it from xsim=linspace(0,25,512) to xsim = (0:1:511)*(12.5/256);

%   Section 1: generate an idealized double exponential fit.
%   First create x axis with 512 time channels and channel width 12.5/256ns
xsim=(0:1:511)*(12.5/256); % changed 2023.11.29

%   Then create y axis with double expnential decay equation; y represent
%   at time x how many photons arrives in this population
ysim=TP*(p1*exp(-xsim/tau1)+p2*exp(-xsim/tau2));

%   Section 2: Turn the exponential histgram distribution into population
%   data.
%   First create a population vector of which each element represent the arrival time of a photon.
Population = [];
%   Align the x lifetime and y photon numbers
Histogram=[xsim' ysim'];

% Turn the photon numbers that arrive at time x into a vector of arrival
% time x with this number of repeats.
counter=1;
for i=1:512
    for j=1:round(Histogram(i,2))
        Population(counter:round(counter+Histogram(i,2)-1))=Histogram(i,1);
    end
    counter=counter+round(Histogram(i,2));
end

% Plot the generated population

figure('Name',PopulationName);
plot(xsim, ysim);
hold on
hist(Population, xsim, 'r');
display(length(Population));
hold off

counts=hist(Population, xsim); % Counts is the 512-element vector that specify for each lifetime channel how many photons there are.

save(PopulationName, 'Population','counts');
