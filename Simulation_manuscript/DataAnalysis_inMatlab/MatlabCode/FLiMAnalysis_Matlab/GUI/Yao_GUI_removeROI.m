function Yao_GUI_removeROI

global stateYao



% Get current image information
numCycle = stateYao.Disp.numCycle;
iImg = stateYao.Disp.iImg;



isDendrite = 0;
if isnumeric( stateYao.CycleIdentification{numCycle,2} )
    isDendrite = 1;
end



if isDendrite
    % Should only be 1 ROI
    %   Remove it
    if ~isempty( stateYao.ROI{numCycle}{iImg} )
        stateYao.ROI{numCycle}{iImg} = [];
    end
    
    
    if length( stateYao.images.I_ROI_stack{numCycle} ) < iImg
        stateYao.images.I_ROI_stack{numCycle}{iImg} = [];
    end
    
    
    if ~isempty( stateYao.images.I_ROI_stack{numCycle}{iImg} )
        stateYao.images.I_ROI_stack{numCycle}{iImg} = zeros(...
            size( stateYao.images.I_ROI_stack{numCycle}{iImg} ,1),...
            size( stateYao.images.I_ROI_stack{numCycle}{iImg} ,2) );
    end
    
    stateYao.ignoreImage(iImg,numCycle) = 1;
    
else
    % Nucleus
    %   How many cells and ellipses are there?
    nCell = size( stateYao.cellIdx{numCycle}{iImg} ,1);
    nEllipse = size( stateYao.ellipseParameters{numCycle}{iImg} ,1);
    
    if nCell ~= nEllipse
        fprintf('%s: Invalid conditions\n',mfilename)
    else
        if nEllipse == 1
            if ~all( stateYao.ellipseParameters{numCycle}{iImg} ==0)
                stateYao.ellipseParameters{numCycle}{iImg} = zeros(1,5);
                stateYao.images.I_nucleus_stack{numCycle}{iImg} = zeros(...
                    size( stateYao.images.I_nucleus_stack{numCycle}{iImg} ,1),...
                    size( stateYao.images.I_nucleus_stack{numCycle}{iImg} ,2) );
                stateYao.images.I_cytoplasm_stack{numCycle}{iImg} = zeros(...
                    size( stateYao.images.I_cytoplasm_stack{numCycle}{iImg} ,1),...
                    size( stateYao.images.I_cytoplasm_stack{numCycle}{iImg} ,2) );
                stateYao.images.I_buffer_stack{numCycle}{iImg} = zeros(...
                    size( stateYao.images.I_buffer_stack{numCycle}{iImg} ,1),...
                    size( stateYao.images.I_buffer_stack{numCycle}{iImg} ,2) );
                
                
                stateYao.applyMask{numCycle}{iImg} = 0;
                
                
                stateYao.funcLink.findNucleus_func{numCycle}{iImg}{1} =...
                    deblank( stateYao.funcLink.findNucleus_func_List(1,:) );
                stateYao.colorNucleus{numCycle}{iImg}{1} =...
                    stateYao.CycleIdentification{numCycle,2};
                
                %                 Yao_GUI_applyROI([],1)
                
            else
                % No ellipse present
            %    stateYao.ignoreImage(iImg, stateYao.numCycle(iCycle) ) = 1;
            end
            
            % % %             stateYao.ignoreImage(iImg, stateYao.numCycle(iCycle) ) = 1;
            
        else
            
            cPos = get(stateYao.Disp.axis.hdl,'CurrentPoint');
            cPos = round( cPos(1,1:2) );
            
            numCycle = stateYao.Disp.numCycle;
            iImg = stateYao.Disp.iImg;
            
            
            
            I_cell_stack = stateYao.images.I_cell_stack{numCycle}{iImg};
            
            for iC = 1:size(I_cell_stack,3)
                iCell = iC;
                if ~I_cell_stack( cPos(2),cPos(1),iC )
                    iCell = [];
                end
                
                if ~isempty(iCell)
                    break
                end
            end
            
            
            
            if isempty(iCell)
                fprintf('%s: Error - Mouse click was outside any cells\n',...
                    mfilename)
            else
                
                stateYao.ellipseParameters{numCycle}{iImg}(iCell,:) = 0;
                stateYao.images.I_nucleus_stack{numCycle}{iImg}(:,:,iCell) = zeros(...
                    size( stateYao.images.I_nucleus_stack{numCycle}{iImg} ,1),...
                    size( stateYao.images.I_nucleus_stack{numCycle}{iImg} ,2) );
                stateYao.images.I_cytoplasm_stack{numCycle}{iImg}(:,:,iCell) = zeros(...
                    size( stateYao.images.I_cytoplasm_stack{numCycle}{iImg} ,1),...
                    size( stateYao.images.I_cytoplasm_stack{numCycle}{iImg} ,2) );
                stateYao.images.I_buffer_stack{numCycle}{iImg}(:,:,iCell) = zeros(...
                    size( stateYao.images.I_buffer_stack{numCycle}{iImg} ,1),...
                    size( stateYao.images.I_buffer_stack{numCycle}{iImg} ,2) );
                
                stateYao.applyMask{numCycle}{iImg}(iCell) = 0;
                
                stateYao.funcLink.findNucleus_func{numCycle}{iImg}{iCell} =...
                    deblank( stateYao.funcLink.findNucleus_func_List(1,:) );
                stateYao.colorNucleus{numCycle}{iImg}{iCell} =...
                    stateYao.CycleIdentification{numCycle,2};
                
                
                if nCell > 1
                    if iCell == stateYao.Disp.cCell
                        
                        temp = stateYao.ellipseParameters{numCycle}{iImg};
                        if ~any( ~all( temp' == 0 ) )
                            % No ellipses
                            stateYao.Disp.cCell = 1;
                        else
                            temp = ~all( temp' == 0 );
                            temp = cat(2,temp',[1:size(temp,2)]');
                            temp = temp( temp(:,1)~=0 ,2);
                            stateYao.Disp.cCell = temp(1);
                        end
                        
                    end
                end
                
                
                
% % %                 if all( all(stateYao.ellipseParameters{iCycle}{iImg}'==0) )
% % %                     stateYao.ignoreImage(iImg, stateYao.numCycle(iCycle) ) = 1;
% % %                 end
                
                
                
            end
            
        end
    end
    
end







Yao_GUI_loadImage



end