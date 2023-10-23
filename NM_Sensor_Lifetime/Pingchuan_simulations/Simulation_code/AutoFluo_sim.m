function AutoFluo_sim = AutoFluo_sim(Autofluorescence_file, AF, SaveName)


xsim=linspace(0,25,256);

%   Section 3: Add autofluorescence from slices.
load(Autofluorescence_file); %Load from a probability distribution of autofluorescence in Autofluorescence_2FLIM001, measured at 30um below the surface of an 
%   untransfected slice, at 920nm, zoom 10, 2.5mW power.
Autofluorescence=zeros(1, AF); %Give each photon zero lifetime to start with.
for i=1:AF
    Autofluorescence(i)=find(histc(rand(),[cumsum(autofluo(:))]))*(25/256); % Draw a lifetime for autofluorescence based on the probability specified in the measured autofluorescence file.
end

% figure;
% hist(Autofluorescence, 256);

% Section 6: Now turn the samples into histogram counts.


[n_auto, xout]=hist(Autofluorescence, xsim);


% Section 7: now save the numbers for analysis
save(SaveName, 'n_auto'); % n gives the photon count per bin; xout gives the lifetime position of each bin.
end

