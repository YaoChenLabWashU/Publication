function Yao_calc_ProjectionAndLifetimeMap %Modified for incorporating slice level data by AM 20230713
%stores cycle pos data in rows and slice data in columns per row/CycPos

global stateYao spc % Note that if you import stateYao from a previously saved file, you need to declare stateYao global in the Command Window first.


if stateYao.processCycles(1) ~= 0
    
    
    stateYao.Results.spc_calculateROIvals.Projection =...
        cell( max(stateYao.numCycle) ,max(spc.datainfo.numberOfZSlices) ); % Initialize an n*n cell specified by n cycle positions and number of slices --AM 20230713 (for 4slices:creates 1x4 cell array).
    stateYao.Results.spc_calculateROIvals.LifetimeMap =...
        cell( max(stateYao.numCycle) ,max(spc.datainfo.numberOfZSlices) );
    
    for numCycle = stateYao.processCycles' %Cycling through different cycle positions
        for j = 1:spc.datainfo.numberOfZSlices % cycle through every slice therein AM 20230713
            % max_cells=1
            % for iImg = 1:size(stateYao.CyclePositions,1)
            % max_cells=the bigger of (max_cells_size( stateYao.ROI{numCycle}{iImg}, 2), max_cells)
            %end
            
            stateYao.Results.spc_calculateROIvals.Projection{numCycle,j} =...
                cell( size(stateYao.CyclePositions,1),1); % Intialize with how many images per cycle position per slice AM 20230713
            stateYao.Results.spc_calculateROIvals.LifetimeMap{numCycle,j} =...
                cell( size(stateYao.CyclePositions,1),1); %Incorporated Yao's correction (AM: 20230919)
            %diff images per row, within each image(=row)diff cols are
            %diff cells
        end
    end
    
    for j = 1:spc.datainfo.numberOfZSlices
        for iImg = 1:size(stateYao.CyclePositions,1) %Cycling through different images in a given cycle position.
            if stateYao.CyclePositions(iImg,numCycle) ~= 0 % If an image exists
                if stateYao.ignoreImage(iImg,numCycle) == 0
                    
                    if isnumeric( stateYao.CycleIdentification{numCycle,2} )
                        % Dendrite -> Search for shift
                        
                        for iCell=1:size( stateYao.ROI{numCycle}{iImg}, 2)
                            
                            temp_projects = stateYao.images.origData.projects{numCycle,j}(:,:,iImg);%128x128 for that image
                            temp_lifetimeMaps = stateYao.images.origData.lifetimeMaps{numCycle,j}(:,:,iImg);
                            
                            I_ROI = stateYao.images.I_ROI_stack{numCycle}{iImg}(:,:,iCell);%apply mask over slice level data AM 20230713--if {numCycle,j}error: index cannot exceed 1
                            
                            
                            
                            I_mask = I_ROI;
                            
                            % Projection values
                            val_Projection = Yao_calc_Projection(...
                                temp_projects,...
                                I_mask);
                            
                            % Lifetime values
                            val_LifetimeMap = Yao_calc_Lifetime(...
                                temp_projects,...
                                temp_lifetimeMaps,...
                                I_mask);
                            
                            
                            
                            
                            stateYao.Results.spc_calculateROIvals.Projection{numCycle,j}{iImg}(iCell) =...
                                val_Projection;
                            stateYao.Results.spc_calculateROIvals.LifetimeMap{numCycle,j}{iImg}(iCell) =...
                                val_LifetimeMap;
                        end
                    else
                        % Nucleus
                        temp_projects = stateYao.images.origData.projects{numCycle,j}(:,:,iImg);
                        temp_lifetimeMaps = stateYao.images.origData.lifetimeMaps{numCycle,j}(:,:,iImg);
                        I_cell_stack = stateYao.images.I_cell_stack{numCycle,j}{iImg};
                        
                        stateYao.Results.spc_calculateROIvals.Projection{numCycle,j}{iImg} =...
                            zeros( size(I_cell_stack,3) ,2);
                        stateYao.Results.spc_calculateROIvals.LifetimeMap{numCycle,j}{iImg} =...
                            zeros( size(I_cell_stack,3) ,2);
                        
                        for iCell = 1:size(I_cell_stack,3)
                            I_nucleus = stateYao.images.I_nucleus_stack{numCycle,j}{iImg}(:,:,iCell);
                            I_cytoplasm = stateYao.images.I_cytoplasm_stack{numCycle,j}{iImg}(:,:,iCell);
                            
                            %                     I_cell = I_cell_stack(:,:,iCell);
                            %                     se = strel('disk', stateYao.erodeCell_calc );
                            %                     I_cell = imerode(I_cell,se);
                            %                     for i1 = 1:size(I_cell,1)
                            %                         I_cytoplasm(i1,:) = I_cell(i1,:).*I_cytoplasm(i1,:);
                            %                     end
                            
                            
                            for iMask = 1:2
                                if iMask == 1
                                    I_mask = I_nucleus;
                                else
                                    I_mask = I_cytoplasm;
                                end
                                
                                
                                %                         numCycle
                                %                         iImg
                                %                         iCell
                                %                         iMask
                                %                         size(I_mask)
                                
                                % Projection values
                                val_Projection = Yao_calc_Projection(...
                                    temp_projects,...
                                    I_mask);
                                
                                % Lifetime values
                                val_LifetimeMap = Yao_calc_Lifetime(...
                                    temp_projects,...
                                    temp_lifetimeMaps,...
                                    I_mask);
                                %                         % Projection values
                                %                         val_Projection =...
                                %                             sum(sum( temp_projects.*I_mask ))/sum(sum( I_mask ));
                                %
                                %                         % Lifetime values
                                %                         nTimesTau = I_mask .*temp_projects .*temp_lifetimeMaps;
                                %
                                %                         val_LifetimeMap =...
                                %                             sum(nTimesTau(:))/...
                                %                             sum( temp_projects(:).*I_mask(:) );
                                
                                
                                
                                stateYao.Results.spc_calculateROIvals.Projection{numCycle,j}{iImg}(iCell,iMask) =...
                                    val_Projection;
                                stateYao.Results.spc_calculateROIvals.LifetimeMap{numCycle,j}{iImg}(iCell,iMask) =...
                                    val_LifetimeMap;
                                
                            end
                            
                        end
                        
                        
                        
                    end
                    
                    
                end
            end
        end
    end
end



end
