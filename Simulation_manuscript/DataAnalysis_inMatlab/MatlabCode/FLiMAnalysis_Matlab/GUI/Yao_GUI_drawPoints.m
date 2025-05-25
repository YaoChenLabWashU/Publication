function Yao_GUI_drawPoints(pts,iCell,cond)

global stateYao



numCycle = stateYao.Disp.numCycle;
iImg = stateYao.Disp.iImg;


if ~isnumeric( stateYao.CycleIdentification{numCycle,2} )
    idxList = 1:size( stateYao.cellIdx{numCycle}{iImg} ,1);
    idxList = idxList( stateYao.cellIdx{numCycle}{iImg}(:,1) == iCell );
    cellID = stateYao.cellIdx{numCycle}{iImg}(idxList,2);
else
    try
        cellID = stateYao.cellIdx{numCycle}{iImg}(iCell,2);
    catch
        currLen = size(stateYao.cellIdx{numCycle}{iImg},1);
        stateYao.cellIdx{numCycle}{iImg}(currLen+1,:) = [currLen+1, currLen+1, 0,0,0,0];
        cellID = stateYao.cellIdx{numCycle}{iImg}(iCell,2);
    end
end




justPoints = 0;
if ~exist('cond','var')
    justPoints = 1;
elseif ~ischar(cond)
    justPoints = 1;
elseif strcmp(cond,'pts')
    justPoints = 1;
else
    justPoints = 0;
end



if justPoints
    if any(stateYao.Disp.ROI.userSelection.hdl ~=0)
    if length(stateYao.Disp.ROI.userSelection.hdl) >= iCell
    if stateYao.Disp.ROI.userSelection.hdl(iCell) ~= 0
        delete(stateYao.Disp.ROI.userSelection.hdl(iCell))
        delete(stateYao.Disp.ROI.userSelectionUnder.hdl(iCell))
        stateYao.Disp.ROI.userSelection.hdl(iCell) = 0;
        stateYao.Disp.ROI.userSelectionUnder.hdl(iCell) = 0;
    end
    end
    end

    
    
    axes(stateYao.Disp.axis.hdl)
    hold on
    if cellID == stateYao.Disp.cCell
        stateYao.Disp.ROI.userSelectionUnder.hdl(iCell) = plot(...
            pts(:,1),...
            pts(:,2),...
            'm.','MarkerSize',26);
        stateYao.Disp.ROI.userSelection.hdl(iCell) = plot(...
            pts(:,1),...
            pts(:,2),...
            'w.','MarkerSize',14);
        hold off
    else
%         R = 0+ (iCell-1)*0.2;
%         G = 0;
% %         B = 1;
%         B = 1- (iCell-1)*0.1;
        if cellID <= size( stateYao.colorList ,1)
            colorCode = stateYao.colorList(cellID);
        else
            colorCode = stateYao.colorList(end);
        end
        stateYao.Disp.ROI.userSelectionUnder.hdl(iCell) = plot(...
            pts(:,1),...
            pts(:,2),...
            'LineStyle','none',...
            'Marker','.',...
            'Color', colorCode ,...
            'MarkerSize',26);
        stateYao.Disp.ROI.userSelection.hdl(iCell) = plot(...
            pts(:,1),...
            pts(:,2),...
            'w.','MarkerSize',14);
        hold off
    end
    drawnow
    
    
    
    
    
    stateYao.Disp.ROI.userSelection.data{iCell} = pts;
%     if size(stateYao.Disp.ROI.userSelection.data,1) == size(pts,1)
%         stateYao.Disp.ROI.userSelection.data(:,:,iCell) = pts;
%     else
%         stateYao.Disp.ROI.userSelection.data(1:size(pts,1),:,iCell) = pts;
%         if size(stateYao.Disp.ROI.userSelection.data,1) > size(pts,1)
%             stateYao.Disp.ROI.userSelection.data(size(pts,1)+1:end,:,iCell) =...
%                 Nan;
%         else
%             
%         end
%     end
    
    
    
else
    if strcmp(cond,'buffer')
        if any(stateYao.Disp.ROI.buffer.hdl ~=0)
        if length(stateYao.Disp.ROI.buffer.hdl) >= iCell
        if stateYao.Disp.ROI.buffer.hdl(iCell) ~=0
            delete(stateYao.Disp.ROI.buffer.hdl(iCell))
            delete(stateYao.Disp.ROI.bufferUnder.hdl(iCell))
            stateYao.Disp.ROI.buffer.hdl(iCell) = 0;
            stateYao.Disp.ROI.bufferUnder.hdl(iCell) = 0;
        end
        end
        end
        
        
        
%         I_buffer = stateYao.I_buffer_stack{...
%             stateYao.Disp.iCycle}{stateYao.Disp.iImg}(:,:,iCell);
%         
%         if any(any(I_buffer))
%         I_buffer = Yao_generic_fillPts(I_buffer,[]);
% %         I_buffer = imfill(I_buffer,'holes');
%         [pixelList_perim] = Yao_generic_getPerimeter(I_buffer,'PixelList');
%         
%         X = pixelList_perim(:,2);
%         Y = pixelList_perim(:,1);
%         
%         axes(stateYao.Disp.axis.hdl)
%         hold on
%         stateYao.Disp.ROI.bufferUnder.hdl(iCell) =...
%             plot( X,Y,'b.','MarkerSize',12 );
%         stateYao.Disp.ROI.buffer.hdl(iCell) =...
%             plot( X,Y,'w.','MarkerSize',4 );
%         hold off
%         
%         uistack(stateYao.Disp.ROI.buffer.hdl(iCell),'bottom')
%         uistack(stateYao.Disp.ROI.buffer.hdl(iCell),'up')
%         uistack(stateYao.Disp.ROI.bufferUnder.hdl(iCell),'bottom')
%         uistack(stateYao.Disp.ROI.bufferUnder.hdl(iCell),'up')
%         drawnow
%         end
        
        
        
        
% % %         if size(stateYao.temp.ROI.ellipseParameters,1) >= iCell
% % %         if ~all( stateYao.temp.ROI.ellipseParameters(iCell,:)==0 )
% % %         
% % %         I_cell = stateYao.I_cell_stack{stateYao.Disp.iCycle}{...
% % %             stateYao.Disp.iImg}(:,:,iCell);
% % %         
% % %         x0 = stateYao.temp.ROI.ellipseParameters(iCell,1);
% % %         y0 = stateYao.temp.ROI.ellipseParameters(iCell,1);
% % %         semimajor_axis = stateYao.temp.ROI.ellipseParameters(iCell,1);
% % %         semiminor_axis = stateYao.temp.ROI.ellipseParameters(iCell,1);
% % %         phi = deg2rad( stateYao.temp.ROI.ellipseParameters(iCell,1) );
% % %         
% % %         
% % %         
% % %         t = linspace(0,2*pi(),40);
% % %         X = x0 + semimajor_axis *cos(t)*cos(phi) - semiminor_axis *sin(t)*sin(phi);
% % %         Y = y0 + semimajor_axis *cos(t)*sin(phi) + semiminor_axis *sin(t)*cos(phi);
% % %         clear t
% % %         
% % %         X = round( real(X') );
% % %         Y = round( real(Y') );
% % %         
% % %         
% % %         
% % %         I_nucleus = Yao_generic_fillPts([Y X],[size(I_cell,1) size(I_cell,2)]);
% % %         
% % %         [I_nucleus,I_cytoplasm,I_buffer] = Yao_generic_zoneID(I_cell,I_nucleus);
% % %         
% % %         
% % %         
% % %         [pixelList_perim] = Yao_generic_getPerimeter(I_buffer,'PixelList');
% % %         
% % %         X = pixelList_perim(:,2);
% % %         Y = pixelList_perim(:,1);
% % %         
% % %         axes(stateYao.Disp.axis.hdl)
% % %         hold on
% % %         stateYao.Disp.ROI.bufferUnder.hdl(iCell) =...
% % %             plot( X,Y,'b-','LineWidth',4 );
% % %         stateYao.Disp.ROI.buffer.hdl(iCell) =...
% % %             plot( X,Y,'w-','LineWidth',1 );
% % %         hold off
% % %         
% % %         uistack(stateYao.Disp.ROI.buffer.hdl(iCell),'bottom')
% % %         uistack(stateYao.Disp.ROI.buffer.hdl(iCell),'up')
% % %         uistack(stateYao.Disp.ROI.bufferUnder.hdl(iCell),'bottom')
% % %         uistack(stateYao.Disp.ROI.bufferUnder.hdl(iCell),'up')
% % %         drawnow
% % %         
% % %         end
% % %         end
        
    else
        
        
        
        
        
    
    
    if any(stateYao.Disp.ROI.ellipse.hdl ~=0)
    if length(stateYao.Disp.ROI.ellipse.hdl) >= iCell
    if stateYao.Disp.ROI.ellipse.hdl(iCell) ~=0
        delete(stateYao.Disp.ROI.ellipse.hdl(iCell))
        delete(stateYao.Disp.ROI.ellipseUnder.hdl(iCell))
        stateYao.Disp.ROI.ellipse.hdl(iCell) = 0;
        stateYao.Disp.ROI.ellipseUnder.hdl(iCell) = 0;
    end
    end
    end
    
    
    
    if strcmp(cond,'line')
        X = pts(:,1);
        Y = pts(:,2);
        X = cat(1,X,X(1));
        Y = cat(1,Y,Y(1));
        
        
        ROI_pts = [];
        
        x = X;
        y = Y;
        
        n = size(x,1);
        for k=1:n-1
            %         for k = 1:3
            x1 = x(k);
            y1 = y(k);
            
            x2 = x(k+1);
            y2 = y(k+1);
            
            
            
            x1 = round(x1);
            x2 = round(x2);
            y1 = round(y1);
            y2 = round(y2);
            
            
            
            if abs(x2-x1) < 2 || abs(y2-y1) < 2
                if abs(x2-x1) < 2 && abs(y2-y1) < 2
                    x3 = x1;
                    y3 = y1;
                else
                    if abs(x2-x1) < 2
                        if y1 < y2
                            y3 = y1+1:y2-1;
                        else
                            y3 = y2+1:y1-1;
                        end
                        x3 = x1*ones(1,size(y3,2));
                    else
                        if x1 < x2
                            x3 = x1+1:x2-1;
                        else
                            x3 = x2+1:x1-1;
                        end
                        y3 = y1*ones(1,size(x3,2));
                    end
                end
                
            else
                if abs(x2-x1) > abs(y2-y1)
                    if x1 < x2
                        x3 = x1+1:x2-1;
                        y3 = round( interp1([x1 x2],[y1 y2],x3) );
                    else
                        x3 = x2+1:x1-1;
                        y3 = round( interp1([x2 x1],[y2 y1],x3) );
                    end
                else
                    if y1 < y2
                        y3 = y1+1:y2-1;
                        x3 = round( interp1([y1 y2],[x1 x2],y3) );
                    else
                        y3 = y2+1:y1-1;
                        x3 = round( interp1([y2 y1],[x2 x1],y3) );
                    end
                end
                
            end
            
            
            
            if isempty(ROI_pts)
                ROI_pts = [x3' y3'];
            else
                d1 = hypot(...
                    ROI_pts(end,1) - x3(1) ,...
                    ROI_pts(end,2) - y3(1) );
                d2 = hypot(...
                    ROI_pts(end,1) - x3(end) ,...
                    ROI_pts(end,2) - y3(end) );
                
                if d1 > d2
                    ROI_pts = cat(1,ROI_pts,[x3(end:-1:1)' y3(end:-1:1)']);
                else
                    ROI_pts = cat(1,ROI_pts,[x3' y3']);
                end
                
            end
            
        end
        
        
        
        stateYao.Disp.ROI.ellipse.data{iCell} = ROI_pts;
        for iCell_temp = 1:length(stateYao.Disp.ROI.ellipse.data)
            if any(any( stateYao.Disp.ROI.ellipse.data{iCell_temp} == 0))
                for i1 = 1:size(stateYao.Disp.ROI.ellipse.data{iCell_temp},1)
                    if any( stateYao.Disp.ROI.ellipse.data{iCell_temp}(i1,:) == 0)
                        stateYao.Disp.ROI.ellipse.data{iCell_temp}(i1,:) = NaN;
                    end
                end
            end
        end
        
        
        
    elseif strcmp(cond,'ellipse')
        
        [A] = Yao_generic_fitEllipse(pts);
        
        [x0,y0,semimajor_axis,semiminor_axis,phi] =...
            Yao_generic_convertEllipseEqt_quad2std(A);
        
        
        [phi] = Yao_generic_getOrientation(pts,'Deg');
        phi = deg2rad(phi);
        
        
        t = linspace(0,2*pi(),40);
        X = x0 + semimajor_axis *cos(t)*cos(phi) - semiminor_axis *sin(t)*sin(phi);
        Y = y0 + semimajor_axis *cos(t)*sin(phi) + semiminor_axis *sin(t)*cos(phi);
        clear t
        
        X = real(X');
        Y = real(Y');
        
        
        
        stateYao.Disp.ROI.ellipse.data{iCell} = [X Y];
        
% % %         stateYao.temp.ROI.ellipseParameters(iCell,:) =...
% % %             [x0 y0 semimajor_axis semiminor_axis rad2deg(phi)];
        
    end
    
    
    
    axes(stateYao.Disp.axis.hdl)
    hold on
    if cellID == stateYao.Disp.cCell
        stateYao.Disp.ROI.ellipseUnder.hdl(iCell) =...
            plot( X,Y,'m-','LineWidth',4 );
        stateYao.Disp.ROI.ellipse.hdl(iCell) =...
            plot( X,Y,'w-','LineWidth',1 );
    else        
        
%         R = 0+ (iCell-1)*0.2;
%         G = 0;
% %         B = 1;
%         B = 1- (iCell-1)*0.1;
        if cellID < size( stateYao.colorList ,1)
            colorCode = stateYao.colorList(cellID);
        else
            colorCode = stateYao.colorList(end);
        end
        stateYao.Disp.ROI.ellipseUnder.hdl(iCell) =...
            plot( X,Y,...
            'LineStyle','-',...
            'Marker','none',...
            'Color', colorCode ,...
            'LineWidth',4 );
        stateYao.Disp.ROI.ellipse.hdl(iCell) =...
            plot( X,Y,'w-','LineWidth',1 );
    end
    hold off
    
    uistack(stateYao.Disp.ROI.ellipse.hdl(iCell),'bottom')
    uistack(stateYao.Disp.ROI.ellipse.hdl(iCell),'up')
    uistack(stateYao.Disp.ROI.ellipseUnder.hdl(iCell),'bottom')
    uistack(stateYao.Disp.ROI.ellipseUnder.hdl(iCell),'up')
    drawnow
    
    end
end



end