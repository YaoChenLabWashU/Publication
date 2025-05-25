function Yao_generic_loadImage_v2(numImg,cond)

% cond can be empty or 'fast'


if ~exist('cond','var')
    cond = [];
end
% if isempty(cond)
%     cond = '
% end




global spc



% Tell spc_main to load new image
spc_openFiles(numImg,[])



loadExtra = 1;
if ~isempty(cond)
if strcmp(lower(cond),'fast')
    loadExtra = 0;
end
end




% Make changes to Tau and upper/lower limits
betahat=spc_fitexp2prfGY(1);

% Redraw lifetime map
spc_adjustTauOffset(1)


    
if loadExtra    
    spc.switchess{1,1}.lifeLimitUpper =...
        spc.fits{1,1}.avgTau -0.25;
    spc.switchess{1,1}.lifeLimitLower =...
        spc.fits{1,1}.avgTau +0.25;
    
    
    
    spc_redrawSetting
end