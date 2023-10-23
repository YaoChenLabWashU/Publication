% Read in observed responses, which are muscarinic responses and forskolin
% response.
mus=xlsread('mus');
fsk=xlsread('fsk');

% Read in the predictors, which are all other conditions summarized.

X=xlsread('GLMX');

% Read in the predictors, but exclude the predictor that we want to plot
% the relationship with responses, which is the photon counts or P-cell here.

X_nophoton=xlsread('GLMX_nophotoncount');
X_noPcell=xlsread('GLMX_noPcell');

% Read in the excluded predictors

photoncounts=xlsread('Photoncount');
Pcell=xlsread('Pcell')

% Calculate the coefficients of predictors to responses when there is no photon count predictor.
coef_nophoton_mus=glmfit(X_nophoton,mus);
coef_noPcell_mus=glmfit(X_nophoton,mus);
coef_nophoton_fsk=glmfit(X_nophoton,fsk);
coef_noPcell_fsk=glmfit(X_nophoton,fsk);

% Calculate the coefficients of the rest of predictors to the excluded
% predictors

coef_photon=glmfit(X_nophoton,photoncounts);
coef_Pcell=glmfit(X_noPcell,Pcell);

% Calculate the residues of responses by predictors
  % remember to add the constant factor 1s in the X
a=ones((size(X,1)),1);

residue_mus_nophoton=mus-[a X_nophoton]*coef_nophoton_mus;
residue_mus_noPcell=mus-[a X_noPcell]*coef_noPcell_mus;
residue_fsk_nophoton=fsk-[a X_nophoton]*coef_nophoton_fsk;
residue_fsk_noPcell=fsk-[a X_noPcell]*coef_noPcell_fsk;

% Calculate the residues of excluded predictors

residue_photon=photoncounts-[a X_nophoton]*coef_photon;
residue_Pcell=Pcell-[a X_noPcell]*coef_Pcell;

% plot the residues vs residues

