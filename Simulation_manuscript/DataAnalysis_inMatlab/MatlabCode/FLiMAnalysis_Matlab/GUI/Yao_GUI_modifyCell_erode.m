function Yao_GUI_modifyCell_erode

% Dilate modifier
se = strel('disk',1);



global stateYao



% Load data
img = stateYao.Disp.modifyCell.origData.rgbLifetimes;
I_cell = stateYao.Disp.modifyCell.data.I_cell;



% Dilate
I_cell = imerode(I_cell,se);



% Apply
[pixelList_perim] = Yao_generic_getPerimeter(I_cell,'PixelList');
for iPt = 1:size(pixelList_perim,1)
    img(...
        pixelList_perim(iPt,1),...
        pixelList_perim(iPt,2), :) = 1;
end



% Display
set(stateYao.Disp.modifyCell.plot.hdl,...
    'CData',...
    img )



% Save
stateYao.Disp.modifyCell.data.I_cell = I_cell;
stateYao.Disp.modifyCell.data.img = img;