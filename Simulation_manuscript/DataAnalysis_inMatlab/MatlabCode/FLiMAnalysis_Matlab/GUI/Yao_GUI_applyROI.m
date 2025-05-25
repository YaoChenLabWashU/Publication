function Yao_GUI_applyROI(pts,iCell,cond)

global stateYao ghYao

numCycle = stateYao.Disp.numCycle;
iImg = stateYao.Disp.iImg;



if ~exist('iCell','var')
    iCell = 1;
end




if any(stateYao.Disp.ROI.userSelection.hdl~=0)
    if length(stateYao.Disp.ROI.userSelection.hdl) >= iCell
        if stateYao.Disp.ROI.userSelection.hdl(iCell) ~= 0
            delete(stateYao.Disp.ROI.userSelection.hdl(iCell))
            delete(stateYao.Disp.ROI.userSelectionUnder.hdl(iCell))
            stateYao.Disp.ROI.userSelection.hdl(iCell) = 0;
            stateYao.Disp.ROI.userSelectionUnder.hdl(iCell) = 0;
        end
    end  
end

if any(stateYao.Disp.ROI.ellipse.hdl ~=0)
    if length(stateYao.Disp.ROI.ellipse.hdl) >= iCell
        if stateYao.Disp.ROI.ellipse.hdl(iCell) ~= 0
            delete(stateYao.Disp.ROI.ellipse.hdl(iCell))
            delete(stateYao.Disp.ROI.ellipseUnder.hdl(iCell))
            stateYao.Disp.ROI.ellipse.hdl(iCell) = 0;
            stateYao.Disp.ROI.ellipseUnder.hdl(iCell) = 0;
        end
    end  
end

if any(stateYao.Disp.ROI.cell.hdl ~=0)
    if length(stateYao.Disp.ROI.cell.hdl) >= iCell
        if stateYao.Disp.ROI.cell.hdl(iCell) ~= 0
            delete(stateYao.Disp.ROI.cell.hdl(iCell))
            delete(stateYao.Disp.ROI.cellUnder.hdl(iCell))
            stateYao.Disp.ROI.cell.hdl(iCell) = 0;
            stateYao.Disp.ROI.cellUnder.hdl(iCell) = 0;
        end
    end  
end
drawnow



if isnumeric( stateYao.CycleIdentification{numCycle,2} )
    % Dendrite
    
    if ~exist('pts','var') || isempty(pts)
        pts = [];
        if ~isempty( stateYao.ROI{numCycle}{iImg} )
            for iCell = 1:size( stateYao.ROI{numCycle}{iImg} ,2)
                if ~isempty( stateYao.ROI{numCycle}{iImg}{iCell} )
                    pts = stateYao.ROI{numCycle}{iImg}{iCell};
                    
                    if ~isempty(pts)
                        Yao_GUI_drawPoints(pts,iCell)
                        Yao_GUI_drawPoints(pts,iCell,'line')
                    end
                end
            end
        end
    else   
        if ~isempty(pts)
            Yao_GUI_drawPoints(pts,iCell)
            Yao_GUI_drawPoints(pts,iCell,'line')

            drawBuffer = 1;
            if exist('cond','var')
                if ischar(cond)
                    if strcmp(cond,'limited')
                        drawBuffer = 0;
                    end
                end
            end

            if drawBuffer
                Yao_GUI_drawPoints([],iCell,'buffer')
            end
        end
    end
    
else
    % Nucleus
    
    if size( stateYao.cellIdx{numCycle}{iImg} ,1) == 1
                
        if ~exist('pts','var') || isempty(pts)
            ellipseParameters = stateYao.ellipseParameters{numCycle}{iImg}(iCell,:);
            if all(ellipseParameters==0)
                pts = [];
            else
                ellipseParameters(5) = deg2rad(ellipseParameters(5));
                
                t = linspace(0,2*pi()-2*pi()/5,5); % 6
                X = ellipseParameters(1) +...
                    ellipseParameters(3) *cos(t)*cos( ellipseParameters(5) ) -...
                    ellipseParameters(4) *sin(t)*sin( ellipseParameters(5) );
                Y = ellipseParameters(2) +...
                    ellipseParameters(3) *cos(t)*sin( ellipseParameters(5) ) +...
                    ellipseParameters(4) *sin(t)*cos( ellipseParameters(5) );
                clear t
                
                pts = [X' Y'];
            end
        end
        
        if ~isempty(pts)
            Yao_GUI_drawPoints(pts,iCell)
            Yao_GUI_drawPoints(pts,iCell,'ellipse')
            
            drawBuffer = 1;
            if exist('cond','var')
                if ischar(cond)
                    if strcmp(cond,'limited')
                        drawBuffer = 0;
                    end
                end
            end
            
            if drawBuffer
                Yao_GUI_drawPoints([],iCell,'buffer')
            end
        end
        
        
        
    else
        if ~exist('pts','var') || isempty(pts)
        
            for iCell = 1:size( stateYao.cellIdx{numCycle}{iImg} ,1)
            if stateYao.cellIdx{numCycle}{iImg}(iCell,2) ~= 0
                idxCell = stateYao.cellIdx{numCycle}{iImg}(iCell,1);
            
                if size(stateYao.ellipseParameters{numCycle}{iImg},1) < idxCell
                    break
                else
                    ellipseParameters = stateYao.ellipseParameters{numCycle}{iImg}(idxCell,:);
                    
                    if all(ellipseParameters==0)
                        pts = [];
                    else
                        ellipseParameters(5) = deg2rad(ellipseParameters(5));
                        
                        t = linspace(0,2*pi()-2*pi()/5,5); % 6
                        X = ellipseParameters(1) +...
                            ellipseParameters(3) *cos(t)*cos( ellipseParameters(5) ) -...
                            ellipseParameters(4) *sin(t)*sin( ellipseParameters(5) );
                        Y = ellipseParameters(2) +...
                            ellipseParameters(3) *cos(t)*sin( ellipseParameters(5) ) +...
                            ellipseParameters(4) *sin(t)*cos( ellipseParameters(5) );
                        clear t
                        
                        pts = [X' Y'];
                                                
                    end
                    
                    if ~isempty(pts)
                        Yao_GUI_drawPoints(pts,iCell)
                        Yao_GUI_drawPoints(pts,iCell,'ellipse')
                        
                        drawBuffer = 1;
                        if exist('cond','var')
                            if ischar(cond)
                                if strcmp(cond,'limited')
                                    drawBuffer = 0;
                                end
                            end
                        end
                        
                        if drawBuffer
                            Yao_GUI_drawPoints([],iCell,'buffer')
                        end
                    end
                    
                end
                
            end
            end
        
        else
            
            if ~isempty(pts)
                Yao_GUI_drawPoints(pts,iCell)
                Yao_GUI_drawPoints(pts,iCell,'ellipse')
                
                drawBuffer = 1;
                if exist('cond','var')
                    if ischar(cond)
                        if strcmp(cond,'limited')
                            drawBuffer = 0;
                        end
                    end
                end
                
                if drawBuffer
                    Yao_GUI_drawPoints([],iCell,'buffer')
                end
            end
            
        end
        
    end
    
    
    
end





end