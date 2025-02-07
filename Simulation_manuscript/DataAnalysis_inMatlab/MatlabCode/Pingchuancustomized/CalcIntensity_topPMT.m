function [intensity_top, background] = CalcIntensity_topPMT(reference_image, top_pixels, background_mask, CyclePositions)
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

for i_cycle = CyclePositions

    for i_num = 1:length(stateYao.CyclePositions(:,i_cycle))
        i_acq = stateYao.CyclePositions(i_num,i_cycle);
    
        if i_acq<10
            Tiff_name = [base_name, '00', num2str(i_acq), '.tif'];
        else if i_acq>=10 & i_acq<=99
                Tiff_name = [base_name, '0', num2str(i_acq), '.tif'];
            else
                Tiff_name = [base_name, num2str(i_acq), '.tif'];
            end
        end
    
        try t = Tiff(Tiff_name, 'r');
            imageData = read(t);
            imageData = double(imageData);
            imageData = imageData - background;
            tiff_images{i_num,i_cycle} = imageData;
        catch
            tiff_images{i_num,i_cycle} = [];
            display(['tiff image ', num2str(i_acq), ' is empty'])
            ignore_image = ignore_image +1;
        end
        
        
    end

end

intensity_top = {};

for i_cycle = CyclePositions
    intensity_top{i_cycle} = NaN(length(stateYao.CyclePositions(:,i_cycle)), size(stateYao.ROI{i_cycle}{1},2));

    for i = 1:length(stateYao.CyclePositions(:,i_cycle))
        if stateYao.CyclePositions(i,i_cycle) ~= 0
            tiff_image = tiff_images{i, i_cycle};
    
            for j = 1:size(stateYao.ROI{1,1}{1},2)
                if top_pixels
    
                    I_mask = stateYao.I_ROI_stack_TopPixels{i_cycle}{1,i}{j};
                else
                    I_mask = stateYao.images.I_ROI_stack{i_cycle}{i}(:,:,j);
                end
    
                if isempty(tiff_image) ==0
                    projection = Yao_calc_Projection(tiff_image, I_mask);
                    intensity_top{i_cycle}(i,j) = projection;
                
                end
            end
        end
    end
end

end
