function CalculateROIBasedOnTopPixels(PixelValueThreshold, fractionofpixels, CyclePositions)
%This function calculates lifetime and intensity of the top fraction of
%pixels for pixel values above the specified PixelValueThreshold, currently
%writtn for "dendrite" aka ROI registration mode only.

% The purpose of the function is to deal with imperfect ROI selection, and
% focus change. It 1) calculates the smallest number of pixels above the
% PixelValueThreshold for a given cell through all images; 2) captures a
% fraction of this number of pixels for all images; and 3) calculates the
% values.

% Recommended values for the inputs: PixelValueThreshold=5 or 10 for ACh
% sensor data (dim), fractionofpixels=0.66
% E.g. CalculateROIBasedOnTopPixels(10,0.66);

% You would load stateYao from previous analyses, and then run this code,
% and then you need to resave stateYao.

% It was created on 11/23/2022 by Yao Chen.


%
global stateYao
stateYao.Results.ROICalculation.fractionofpixels=fractionofpixels; %record analysis conditions
stateYao.Results.ROICalculation.PixelValueThreshold=PixelValueThreshold;

for i_numCycle = 1:length(CyclePositions) % Loop through cycle positions
    numCycle = CyclePositions(i_numCycle);

    isDendrite = 0;
    if isnumeric( stateYao.CycleIdentification{numCycle,2} ) %Are we dealing with "dendrite" mode?
        isDendrite = 1;
    end
    
    if isDendrite % continue the analysis if we are in dendrite mode.
        
        % First, we will figure out How many pixels are above a threshold
        % for each ROI and each image.
        for iImg = 1:size(stateYao.CyclePositions ,1)
            nCell=0;
            if stateYao.CyclePositions(iImg,numCycle) ~= 0
                if stateYao.ignoreImage(iImg,numCycle) == 0
                    % if max(max((stateYao.images.I_ROI_stack{numCycle}{iImg})))~=0
                    nCell = max([nCell size(stateYao.images.I_ROI_stack{numCycle}{iImg},3)]);
                end
                for iCell = 1:nCell
                    Intensity_map=stateYao.images.origData.projects{numCycle}(:,:,iImg);
                    ROI_mask = stateYao.images.I_ROI_stack{numCycle}{iImg}(:,:,iCell);

                    if sum(sum(ROI_mask)) == 0
                        display(['Cycle position ', num2str(numCycle), ', cell ', num2str(iCell), ' in image ', num2str(iImg), ', mask is empty.'])
                    end
                    stateYao.Intensity_ROI{numCycle}{iImg}{iCell}=ROI_mask.*Intensity_map;% Now get the pixel intensity values of all the pixels within a mask.
                    stateYao.Intensity_ROI_NonZeroPixelValues{numCycle}{iImg}{iCell}=nonzeros(stateYao.Intensity_ROI{numCycle}{iImg}{iCell}); % Get a vector of non-zero pixels.
                    % h=histogram(Intensity_ROI2); %plotted a histogram of non-zero pixels,
                    % and decided that a threshold of 5 or 10 is good.
                    
                    % h.Normalization='probability';
                    % h.BinWidth=10;
                    stateYao.pixelaboveThreshold{numCycle}{iImg, iCell}=sum(stateYao.Intensity_ROI_NonZeroPixelValues{numCycle}{iImg}{iCell}>PixelValueThreshold); % Now getting the number of pixels above the threshold of 10 in an image.
                end
            end
        end
        
        %Now, we will determine the number of pixels we will use for each
        %mask.
        % nImg=size(stateYao.pixelaboveThreshold{numCycle},1) %How many images do we have.
        for iCell=1:size(stateYao.pixelaboveThreshold{numCycle},2) %How many cells do we have.
            all_pixelaboveThreshold = cell2mat(stateYao.pixelaboveThreshold{numCycle}(:,iCell));
            stateYao.PixelNumberThreshold{numCycle,iCell}=min(all_pixelaboveThreshold(all_pixelaboveThreshold > 0)); %the smallest number of pixel numbers above 10 across all images
            stateYao.PixelNumberThreshold{numCycle,iCell}=round(stateYao.PixelNumberThreshold{numCycle,iCell}*fractionofpixels); %We will get a fraction of these pixels.
        end
        
        
        % We will calculate the lifetime and intensity values of the top N pixels
        % (judged by intensity), with N specified by stateYao.PixelNumberThreshold{numCycle,iCell}
        
        for iImg=1:size(stateYao.CyclePositions,1)
            nCell=0;
            if stateYao.CyclePositions(iImg,numCycle) ~= 0
                if stateYao.ignoreImage(iImg,numCycle) == 0
                    % if max(max((stateYao.images.I_ROI_stack{numCycle}{iImg})))~=0
                    nCell = max([nCell size(stateYao.images.I_ROI_stack{numCycle}{iImg},3)]);
                end
                for iCell = 1:nCell % Loop through all cells
                    if isempty(stateYao.Intensity_ROI_NonZeroPixelValues{numCycle}{iImg}{iCell}) == 0
                        B=maxk(stateYao.Intensity_ROI_NonZeroPixelValues{numCycle}{iImg}{iCell},stateYao.PixelNumberThreshold{numCycle,iCell}); % Get a fraction of the pixels
                        stateYao.PixelValueThreshold{numCycle}{iImg}{iCell}=min(B); %We want pixels at this value or above.
                        A=stateYao.Intensity_ROI{numCycle}{iImg}{iCell};
                        % stateYao.I_ROI_stack_exp1{numCycle}{iImg}{iCell}=double(A>10); % mask of any pixesl above 10
                        stateYao.I_ROI_stack_TopPixels{numCycle}{iImg}{iCell}=double(A>stateYao.PixelValueThreshold{numCycle}{iImg}{iCell}); % mask that includes top fraction of the pixels
                    
                        %calculate new intensity and lifetime
                        temp_projects = stateYao.images.origData.projects{numCycle}(:,:,iImg);
                        temp_lifetimeMaps = stateYao.images.origData.lifetimeMaps{numCycle}(:,:,iImg);
                        
                        % Projection values
                        % stateYao.Results.spc_calculateROIvals.Projection_exp1{numCycle}{iImg}(iCell) = Yao_calc_Projection(temp_projects,stateYao.I_ROI_stack_exp1{numCycle}{iImg}{iCell}); % Update intensity
                        
                        stateYao.Results.spc_calculateROIvals.Projection_TopPixels{numCycle}{iImg}(iCell) = Yao_calc_Projection(temp_projects,stateYao.I_ROI_stack_TopPixels{numCycle}{iImg}{iCell}); % Update intensity
                        stateYao.Results.spc_calculateROIvals.Lifetime_TopPixels{numCycle}{iImg}(iCell) = Yao_calc_Lifetime(temp_projects,temp_lifetimeMaps,stateYao.I_ROI_stack_TopPixels{numCycle}{iImg}{iCell}); % Update lifetime
                    else
                        stateYao.Results.spc_calculateROIvals.Projection_TopPixels{numCycle}{iImg}(iCell) = NaN; % Update intensity
                        stateYao.Results.spc_calculateROIvals.Lifetime_TopPixels{numCycle}{iImg}(iCell) = NaN; % Update lifetime
                    end
                    
                end
            end
        end
    end
end
end

