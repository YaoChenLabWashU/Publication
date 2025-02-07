
%
img_num = 777;
numCycle = 1;
iCell = 1;

projection_NonZero = [];

for iImg = 1:img_num

    temp_projects = stateYao.images.origData.projects{numCycle}(:,:,iImg);
    temp_lifetimeMaps = stateYao.images.origData.lifetimeMaps{numCycle}(:,:,iImg);
    temp_TruncLifetimeMaps = stateYao.images.origData.TruncLifetimeMaps{numCycle}(:,:,iImg); % P.M. 07.28.2021
    temp_TruncProjects = stateYao.images.origData.TruncProjects{numCycle}(:,:,iImg); % P.M. 07.28.2021
    temp_rgbLifetimes = stateYao.images.origData.rgbLifetimes{numCycle}(:,:,:,iImg); % P.M. 11.01.2022

    LutRange_zeros = zeros(128, 128); % P.M. 11.01.2022

    % P.M. 11.01.2022
    for ipixel = 1:128
        for jpixel = 1:128
            pixel_rgb = squeeze(temp_rgbLifetimes(ipixel, jpixel, :));
            if sum(pixel_rgb) == 0
                LutRange_zeros(ipixel, jpixel) = 0;
            else
                LutRange_zeros(ipixel, jpixel) = 1;
            end
        end
    end

    I_ROI = stateYao.images.I_ROI_stack{numCycle}{iImg}(:,:,iCell);



    I_mask = I_ROI;

    I_mask_NonZero = I_mask.*LutRange_zeros

   
    % Non zero pixel Projection values % P.M. 11.01.2022
    val_Projection_NonZero = Yao_calc_Projection(...
        temp_projects,...
        I_mask_NonZero);

    projection_NonZero(iImg) = val_Projection_NonZero;
end




