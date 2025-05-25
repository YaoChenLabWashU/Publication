function Yao_run_nucleus_UserSelection_v4(hFig,hAxis,I_cell)

global stateYao
stateYao.temp.I_search = [];
stateYao.temp.ellipseParameters = [];



I_search = [];



% Initialize variables
userPoints = [];
ellipsePoints = [];

h_userSelection = [];
h_ellipse = [];
h_userSelectionUnder = [];
h_ellipseUnder = [];

mDown = 0;
isMoving = 0;
isMoving2 = 0;
idxMove = [];



minNumPtsForEllipse = 5;

size1 = size(I_cell,1);
size2 = size(I_cell,2);



% Apply mouse functions to figure
set(hFig,'WindowButtonDownFcn',@func_mDown)
set(hFig,'WindowButtonUpFcn',@func_mUp)
set(hFig,'WindowButtonMotionFcn',@func_mMove)
set(hFig,'CloseRequestFcn',@func_close)



% % Tell user that they can make their selection now
% msgbox(sprintf('%s\n%s\n\n%s',...
%     'Mark the nucleus with 5 or more points',...
%     'Use left to add or move points, right click to remove',...
%     'When done, close the figure window'))






%%
    function func_mDown(src,eventdata)
    mDown = 1;
    isMoving = 0;
    isMoving2 = 0;
    if ~isempty(userPoints)
        cPos = get(hAxis,'CurrentPoint');
            cPos = cPos(1,1:2);
            
            if all(cPos > 0) &&...
                cPos(1) < size2 &&...
                cPos(2) < size1
            if I_cell( round(cPos(2)),round(cPos(1)) )
            
            mType = get(hFig,'selectiontype');
            
            if strcmp(mType,'normal')
                % Maybe moving a point
                
                d = hypot(...
                    cPos(1) - userPoints(:,1),...
                    cPos(2) - userPoints(:,2) );
                
                [min_val min_idx] = min(d);
                if min_val < 2
                    % Move this point
                    isMoving = 1;
                    idxMove = min_idx;
                    
                else
                    if ~isempty(ellipsePoints)
                    d = hypot(...
                        cPos(1) - ellipsePoints(:,1),...
                        cPos(2) - ellipsePoints(:,2) );
                    
                    [min_val min_idx] = min(d);
                    if min_val < 1
                        % Move this point
                        isMoving2 = 1;
                        idxMove = min_idx;
                    end
                    end
                    
                end
                
            end
            
            end
            end
    end
    end






    function func_mUp(src,eventdata)
    if isMoving
        isMoving = 0;
    elseif isMoving2
        isMoving2 = 0;
    elseif mDown
        mDown = 0;
        
        cPos = get(hAxis,'CurrentPoint');
        cPos = cPos(1,1:2);
        
        if all(cPos > 0) &&...
                cPos(1) < size2 &&...
                cPos(2) < size1
        if I_cell( round(cPos(2)),round(cPos(1)) )
        
        mType = get(hFig,'selectiontype');
        
        if strcmp(mType,'normal')
            % left mouse click, add
            if isempty(userPoints)
                userPoints = cPos;
            else
                userPoints = cat(1,userPoints,cPos);
            end
        else
            % right mouse click, remove
            if ~isempty(userPoints)
                d = hypot(...
                    cPos(1) - userPoints(:,1),...
                    cPos(2) - userPoints(:,2) );
                
                [min_val min_idx] = min(d);
                if min_val < 10
                    userPoints(min_idx,:) = [];
                end
                
            end
        end
        
        
        
        if ~isempty(h_userSelection)
            delete(h_userSelection)
            h_userSelection = [];
            delete(h_userSelectionUnder);
            h_userSelectionUnder = [];
        end
        if ~isempty(h_ellipse)
            delete(h_ellipse)
            h_ellipse = [];
            delete(h_ellipseUnder)
            h_ellipseUnder = [];
        end
        if ~isempty(userPoints)
            drawPoints(userPoints,hAxis)
%             axes(hAxis)
%             hold on
%             h_userSelection = plot(...
%                 userPoints(:,1),...
%                 userPoints(:,2),...
%                 'wo',...
%                 'MarkerFaceColor','k');
%             hold off
%             drawnow
            
            
            
            if size(userPoints,1) >= minNumPtsForEllipse
                [ellipsePoints] = drawEllipse(userPoints,hAxis);
            end
        end
        
        end
        end
    end
    end






    function func_mMove(src,eventdata)
    if isMoving
        isMoving = 0;
        
        cPos = get(hAxis,'CurrentPoint');
        cPos = cPos(1,1:2);
        
        if all(cPos > 0) &&...
                cPos(1) < size2 &&...
                cPos(2) < size1
            
            userPoints(idxMove,:) = cPos;
            
            if ~isempty(h_userSelection)
                delete(h_userSelection)
                h_userSelection = [];
                delete(h_userSelectionUnder);
                h_userSelectionUnder = [];
            end
            if ~isempty(h_ellipse)
                delete(h_ellipse)
                h_ellipse = [];
                delete(h_ellipseUnder);
                h_ellipseUnder = [];
            end
            
            drawPoints(userPoints,hAxis)
%             axes(hAxis)
%             hold on
%             h_userSelection = plot(...
%                 userPoints(:,1),...
%                 userPoints(:,2),...
%                 'wo',...
%                 'MarkerFaceColor','k');
%             hold off
%             drawnow
            
            
            
            if size(userPoints,1) >= minNumPtsForEllipse
                [ellipsePoints] = drawEllipse(userPoints,hAxis);
            end
            
        end
        
        isMoving = 1;
        
        
        
    elseif isMoving2
        isMoving2 = 0;
        
        cPos = get(hAxis,'CurrentPoint');
        cPos = cPos(1,1:2);
        
        if all(cPos > 0) &&...
                cPos(1) < size2 &&...
                cPos(2) < size1
            
            dx = ellipsePoints(idxMove,1) - cPos(1);
            dy = ellipsePoints(idxMove,2) - cPos(2);
            
            
            
            if ~isempty(h_userSelection)
                delete(h_userSelection)
                h_userSelection = [];
                delete(h_userSelectionUnder);
                h_userSelectionUnder = [];
            end
            if ~isempty(h_ellipse)
                delete(h_ellipse)
                h_ellipse = [];
                delete(h_ellipseUnder);
                h_ellipseUnder = [];
            end
            userPoints(:,1) = userPoints(:,1) - dx;
            userPoints(:,2) = userPoints(:,2) - dy;
            ellipsePoints(:,1) = ellipsePoints(:,1) - dx;
            ellipsePoints(:,2) = ellipsePoints(:,2) - dy;
            
            drawPoints(userPoints,hAxis)
%             axes(hAxis)
%             hold on
%             h_userSelection = plot(...
%                 userPoints(:,1),...
%                 userPoints(:,2),...
%                 'wo',...
%                 'MarkerFaceColor','k');
%             hold off
%             drawnow
            
            
            
            if size(userPoints,1) >= minNumPtsForEllipse
                [ellipsePoints] = drawEllipse(userPoints,hAxis);
            end
        end
        
        isMoving2 = 1;        
    end
    end






    function drawPoints(pts,hdl_axis)
    axes(hdl_axis)
    hold on
    h_userSelectionUnder = plot(...
        pts(:,1),...
        pts(:,2),...
        'm.','MarkerSize',26);
    h_userSelection = plot(...
        pts(:,1),...
        pts(:,2),...
        'w.','MarkerSize',14);
    hold off
    drawnow
    end



    function [XY] = drawEllipse(pts,hdl)
    [A] = Yao_generic_fitEllipse(pts);



    [x0,y0,semimajor_axis,semiminor_axis,phi] =...
        Yao_generic_convertEllipseEqt_quad2std(A);
    
    [phi] = Yao_generic_getOrientation(pts,'Deg');
    phi = deg2rad(phi);
    
    
    t = linspace(0,2*pi(),40);
    X = x0 + semimajor_axis *cos(t)*cos(phi) - semiminor_axis *sin(t)*sin(phi);
    Y = y0 + semimajor_axis *cos(t)*sin(phi) + semiminor_axis *sin(t)*cos(phi);
    clear t
    
    X = real(X);
    Y = real(Y);
    
    if ~isempty(h_ellipse)
        delete(h_ellipse)
        h_ellipse = [];
        delete(h_ellipseUnder);
        h_ellipseUnder = [];
    end
    axes(hdl)
    hold on
%     h_ellipseUnder = plot( X,Y,'w.','MarkerSize',18 );
%     h_ellipse = plot( X,Y,'k.','MarkerSize',6 );
    h_ellipseUnder = plot( X,Y,'m-','LineWidth',4 );
    h_ellipse = plot( X,Y,'w-','LineWidth',1 );
    hold off
    drawnow
    
    stateYao.temp.ellipseParameters =...
        [x0 y0 semimajor_axis semiminor_axis rad2deg(phi)];
    
    clear A x0 y0 semimajor_axis semiminor_axis phi   
    
    
    XY = [X' Y'];
    clear X Y
    
    
    
    uistack(h_ellipse,'bottom')
    uistack(h_ellipse,'up')
    uistack(h_ellipseUnder,'bottom')
    uistack(h_ellipseUnder,'up')

    end






    function func_close(src,eventdata)
    
    
    if isempty(userPoints)
        delete(hFig)
    elseif size(userPoints,1) < 5
        delete(hFig)
    else
    set(hFig,'WindowButtonDownFcn',[])
    set(hFig,'WindowButtonUpFcn',[])
    set(hFig,'WindowButtonMotionFcn',[])
    set(hFig,'CloseRequestFcn',[])
    
    if ~isempty(h_userSelection)
        delete(h_userSelection)
        h_userSelection = [];
        delete(h_userSelectionUnder);
        h_userSelectionUnder = [];
    end
    if ~isempty(h_ellipse)
        delete(h_ellipse)
        h_ellipse = [];
        delete(h_ellipseUnder);
        h_ellipseUnder = [];
    end
    
    
    
    I_search = zeros( size(I_cell,1),size(I_cell,2) );
    for iPixel = 1:size(ellipsePoints,1)
        I_search(...
            round(ellipsePoints(iPixel,2)),...
            round(ellipsePoints(iPixel,1)) ) = 1;
    end
    I_search = Yao_generic_fillPts(I_search);
    I_search = Yao_generic_fillPts(I_search);
    
%         % Get ellipse equation
%     [A] = Yao_generic_fitEllipse(userPoints);
%     [x0,y0,semimajor_axis,semiminor_axis,phi] =...
%         Yao_generic_convertEllipseEqt_quad2std(A);
%     clear A
    
    stateYao.temp.I_search = I_search;
%     stateYao.temp.ellipseParameters =...
%         [x0 y0 semimajor_axis semiminor_axis rad2deg(phi)];
    
    
    delete(hFig)
    end
    
    
    
% % %     
% % %     
% % %     % Get ellipse equation
% % %     [A] = Yao_generic_fitEllipse(userPoints);
% % %     [x0,y0,semimajor_axis,semiminor_axis,phi] =...
% % %         Yao_generic_convertEllipseEqt_quad2std(A);
% % %     
% % %     
% % %     
% % %     
% % %     foundCell = 0;
% % %     
% % %     [pixelList] = Yao_generic_getPixels(I_cell);
% % %     
% % %     if min(pixelList(:,1)) < y0 && max(pixelList(:,1)) > y0 &&...
% % %             min(pixelList(:,2)) < x0 && max(pixelList(:,2)) > x0
% % %         
% % %         d = hypot(...
% % %             x0 - pixelList(:,2),...
% % %             y0 - pixelList(:,1) );
% % %         if min(d) < 2
% % %             foundCell = 1;
% % %             stateYao.temp.I_cell = I_cell;
% % %             break
% % %         end
% % %         
% % %     end
% % %     
% % %     
% % %     
% % %     if foundCell
% % %         I_search = zeros( size(I_cell,1),size(I_cell,2) );
% % %         
% % %         for iPixel = 1:size(ellipsePoints,1)
% % %             I_search(...
% % %                 round(ellipsePoints(iPixel,2)),...
% % %                 round(ellipsePoints(iPixel,1)) ) = 1;
% % %         end
% % %         
% % %         I_search = Yao_generic_bw_joinBlocks(I_search);
% % %         
% % %         stateYao.temp.I_search = I_search;
% % %     end
% % %     clear foundCell
% % %     
% % %     
% % %     
% % %     clear A x0 y0 semimajor_axis semiminor_axis phi
% % %     
% % %     clear userPoints ellipsePoints mDown isMoving isMoving2 idxMove
% % %     clear minNumPtsForEllipse size1 size2
% % %     clear h_userSelection h_ellipse
    
    
    
    end

end