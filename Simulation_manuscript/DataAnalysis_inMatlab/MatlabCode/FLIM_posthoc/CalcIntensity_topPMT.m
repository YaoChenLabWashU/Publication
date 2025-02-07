function [intensity_top, background] = CalcIntensity_topPMT(reference_image, num_img, acq_start, background_mask)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here
global stateYao


t = Tiff(reference_image);
imageData = read(t);
imageData = double(imageData);
background = Yao_calc_Projection(imageData, background_mask);
base_name = stateYao.baseName;

tiff_images = {};
ignore_image = 0;

for i = acq_start:num_img

    if i<10
        Tiff_name = [base_name, '00', num2str(i), '.tif'];
    else if i>=10 & i<=99
            Tiff_name = [base_name, '0', num2str(i), '.tif'];
        else
            Tiff_name = [base_name, num2str(i), '.tif'];
        end
    end

    try t = Tiff(Tiff_name, 'r');
        imageData = read(t);
        imageData = double(imageData);
        imageData = imageData - background;
        tiff_images{i-acq_start+1,1} = imageData;
    catch
        tiff_images{i-acq_start+1,1} = [];
        display(['tiff image ', num2str(i), ' is empty'])
        ignore_image = ignore_image +1;
    end
    
    
end

intensity_top = {};
intensity_top{1} = zeros(num_img-acq_start+1, size(stateYao.ROI{1,1}{1},2));

for i = 1:size(stateYao.ROI{1,1}{1},2)
    for j = 1:num_img-acq_start+1-ignore_image
        I_mask = stateYao.I_ROI_stack_TopPixels{1,1}{1,j}{i};
        if isempty(tiff_images{j,1}) ==0
            projection = Yao_calc_Projection(tiff_images{j,1}, I_mask);
            intensity_top{1}(j,i) = projection;
        else
            intensity_top{1}(j,i) = NaN;
        end
    end
end

end