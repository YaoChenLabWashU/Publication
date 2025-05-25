function isvalid=Yao_generic_loadImage_v3(numImg,cond,threshold)
% [mfilename ' 1']

% cond can be empty or 'fast' (not changing LUT) 
% threshold equals photon threshold for data analysis /4, used to screen
% out extremely dim or unfocused images.

if ~exist('cond','var')
    cond = [];
end
% if isempty(cond)
%     cond = '
% end

if ~exist('threshold','var')
    threshold = [];
end


global spc

% Tell spc_main to load new image
spc_openFiles(numImg,[])

isvalid=true;
if ~isempty(threshold)
    if isnumeric(threshold)



onesMatrix = ones(...
    size(spc.projects{1},1),...
    size(spc.projects{1},2) ); % put ones to the size of the image.
  
    
    img_projects =...
        spc.projects{1};
    
    val = Yao_calc_Photon(img_projects,onesMatrix );
    
    if val<threshold % apply to the whole image.
        isvalid=false;
    end
    end
end



    
if isvalid==true
    
    

loadExtra = 1;
if ~isempty(cond)
if strcmp(lower(cond),'fast')
    loadExtra = 0;
end
end




% Make changes to Tau and upper/lower limits
% betahat=spc_fitexp2gaussGY(1);
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
end

