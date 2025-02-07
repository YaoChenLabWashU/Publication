%%
savedData = load('lifetime_collection_1.mat')
lft_roi_recollection1 = [];

for i=1:length(savedData.Acq_nums)

    if savedData.Acq_nums(i)<10
        acqn_file = [gui.gy.filename.base 'FLIM00' num2str(savedData.Acq_nums(i)) '.mat'];
    else
        acqn_file = [gui.gy.filename.base 'FLIM0' num2str(savedData.Acq_nums(i)) '.mat'];
    end
    spc_openCurves(acqn_file)
    
    gui.gy.roiPositions = {};
    gui.gy.roiPositions{1} = savedData.roiPositions{i};
    coordinates_x = savedData.roiPositions{i}(:,1);
    coordinates_y = savedData.roiPositions{i}(:,2);
    gui.gy.rois{1}.mask = poly2mask(coordinates_x, coordinates_y, 128, 128);
    
    spc_calculateROIvals(0)
    lft_roi_recollection1(i) = gui.gy.ROIlife;
end

%%
savedData = load('lifetime_collection_2.mat')
lft_roi_recollection2 = [];

for i=1:length(savedData.Acq_nums)

    if savedData.Acq_nums(i)<10
        acqn_file = [gui.gy.filename.base 'FLIM00' num2str(savedData.Acq_nums(i)) '.mat'];
    else
        acqn_file = [gui.gy.filename.base 'FLIM0' num2str(savedData.Acq_nums(i)) '.mat'];
    end
    spc_openCurves(acqn_file)
    
    gui.gy.roiPositions = {};
    gui.gy.roiPositions{1} = savedData.roiPositions{i};
    coordinates_x = savedData.roiPositions{i}(:,1);
    coordinates_y = savedData.roiPositions{i}(:,2);
    gui.gy.rois{1}.mask = poly2mask(coordinates_x, coordinates_y, 128, 128);
    
    spc_calculateROIvals(0)
    lft_roi_recollection2(i) = gui.gy.ROIlife;
end


%%
%%
savedData = load('lifetime_collection_3.mat')
lft_roi_recollection3 = [];

for i=1:length(savedData.Acq_nums)

    if savedData.Acq_nums(i)<10
        acqn_file = [gui.gy.filename.base 'FLIM00' num2str(savedData.Acq_nums(i)) '.mat'];
    else
        acqn_file = [gui.gy.filename.base 'FLIM0' num2str(savedData.Acq_nums(i)) '.mat'];
    end
    spc_openCurves(acqn_file)
    
    gui.gy.roiPositions = {};
    gui.gy.roiPositions{1} = savedData.roiPositions{i};
    coordinates_x = savedData.roiPositions{i}(:,1);
    coordinates_y = savedData.roiPositions{i}(:,2);
    gui.gy.rois{1}.mask = poly2mask(coordinates_x, coordinates_y, 128, 128);
    
    spc_calculateROIvals(0)
    lft_roi_recollection3(i) = gui.gy.ROIlife;
end

%%
savedData = load('lifetime_collection_4.mat')
lft_roi_recollection4 = [];

for i=1:length(savedData.Acq_nums)

    if savedData.Acq_nums(i)<10
        acqn_file = [gui.gy.filename.base 'FLIM00' num2str(savedData.Acq_nums(i)) '.mat'];
    else
        acqn_file = [gui.gy.filename.base 'FLIM0' num2str(savedData.Acq_nums(i)) '.mat'];
    end
    spc_openCurves(acqn_file)
    
    gui.gy.roiPositions = {};
    gui.gy.roiPositions{1} = savedData.roiPositions{i};
    coordinates_x = savedData.roiPositions{i}(:,1);
    coordinates_y = savedData.roiPositions{i}(:,2);
    gui.gy.rois{1}.mask = poly2mask(coordinates_x, coordinates_y, 128, 128);
    
    spc_calculateROIvals(0)
    lft_roi_recollection4(i) = gui.gy.ROIlife;
end


%%
savedData = load('lifetime_collection_5.mat')
lft_roi_recollection5 = [];

for i=1:length(savedData.Acq_nums)

    if savedData.Acq_nums(i)<10
        acqn_file = [gui.gy.filename.base 'FLIM00' num2str(savedData.Acq_nums(i)) '.mat'];
    else
        acqn_file = [gui.gy.filename.base 'FLIM0' num2str(savedData.Acq_nums(i)) '.mat'];
    end
    spc_openCurves(acqn_file)
    
    gui.gy.roiPositions = {};
    gui.gy.roiPositions{1} = savedData.roiPositions{i};
    coordinates_x = savedData.roiPositions{i}(:,1);
    coordinates_y = savedData.roiPositions{i}(:,2);
    gui.gy.rois{1}.mask = poly2mask(coordinates_x, coordinates_y, 128, 128);
    
    spc_calculateROIvals(0)
    lft_roi_recollection5(i) = gui.gy.ROIlife;
end

%%
lft_roi_recollection  = transpose([lft_roi_recollection1 lft_roi_recollection2 lft_roi_recollection3 lft_roi_recollection4 lft_roi_recollection5]);


%%
Acq_nums_all = [];
savedData = load('lifetime_collection_1.mat')
Acq_nums_all = [Acq_nums_all; savedData.Acq_nums];
savedData = load('lifetime_collection_2.mat')
Acq_nums_all = [Acq_nums_all; savedData.Acq_nums];
savedData = load('lifetime_collection_3.mat')
Acq_nums_all = [Acq_nums_all; savedData.Acq_nums];
savedData = load('lifetime_collection_4.mat')
Acq_nums_all = [Acq_nums_all; savedData.Acq_nums];
savedData = load('lifetime_collection_5.mat')
Acq_nums_all = [Acq_nums_all; savedData.Acq_nums];

%%
% savedData = load('20221004AChsensorHEK001FLIM001_baseline_distribution_collection.mat')
% lft_roi_recollection5 = [];
% 
% for i=1:length(savedData.Acq_nums)
% 
%     if savedData.Acq_nums(i)<10
%         acqn_file = [gui.gy.filename.base 'FLIM00' num2str(savedData.Acq_nums(i)) '.mat'];
%     else
%         acqn_file = [gui.gy.filename.base 'FLIM0' num2str(savedData.Acq_nums(i)) '.mat'];
%     end
%     spc_openCurves(acqn_file)
%     
%     gui.gy.roiPositions = {};
%     gui.gy.roiPositions{1} = savedData.roiPositions{i};
%     coordinates_x = savedData.roiPositions{i}(:,1);
%     coordinates_y = savedData.roiPositions{i}(:,2);
%     gui.gy.rois{1}.mask = poly2mask(coordinates_x, coordinates_y, 128, 128);
%     
%     spc_calculateROIvals(0)
%     lft_roi_recollection5(i) = gui.gy.ROIlife;
% end
% 
% %%
% savedData = load('20221004AChsensorHEK001FLIM001_ACh10_distribution_collection.mat')
% lft_roi_recollection5 = [];
% 
% for i=1:length(savedData.Acq_nums)
% 
%     if savedData.Acq_nums(i)<10
%         acqn_file = [gui.gy.filename.base 'FLIM00' num2str(savedData.Acq_nums(i)) '.mat'];
%     else
%         acqn_file = [gui.gy.filename.base 'FLIM0' num2str(savedData.Acq_nums(i)) '.mat'];
%     end
%     spc_openCurves(acqn_file)
%     
%     gui.gy.roiPositions = {};
%     gui.gy.roiPositions{1} = savedData.roiPositions{i};
%     coordinates_x = savedData.roiPositions{i}(:,1);
%     coordinates_y = savedData.roiPositions{i}(:,2);
%     gui.gy.rois{1}.mask = poly2mask(coordinates_x, coordinates_y, 128, 128);
%     
%     spc_calculateROIvals(0)
%     lft_roi_recollection5(i) = gui.gy.ROIlife;
% end
% 
%%
% 
savedData = load('lifetime_collection_offset0.mat')
lft_roi_recollection5 = [];

for i=1%:length(savedData.Acq_nums)

    if savedData.Acq_nums(i)<10
        acqn_file = [gui.gy.filename.base 'FLIM00' num2str(savedData.Acq_nums(i)) '.mat'];
    else
        acqn_file = [gui.gy.filename.base 'FLIM0' num2str(savedData.Acq_nums(i)) '.mat'];
    end
    spc_openCurves(acqn_file)
    
    gui.gy.roiPositions = {};
    gui.gy.roiPositions{1} = savedData.roiPositions{i};
    coordinates_x = savedData.roiPositions{i}(:,1);
    coordinates_y = savedData.roiPositions{i}(:,2);
    gui.gy.rois{1}.mask = poly2mask(coordinates_x, coordinates_y, 128, 128);
    
    spc_calculateROIvals(0)
    lft_roi_recollection5(i) = gui.gy.ROIlife;
end

%%
createdMask = boundarymask(gui.gy.rois{1}.mask);

B = imoverlay(spc.rgbLifetimes{1}, createdMask);
figure
imshow(B)
