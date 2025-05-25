function Yao_mouseFunc_modifyCell_trim_mMove(src,eventdata)

global stateYao



if src == stateYao.Disp.modifyCell.fig.hdl
    % Get current mouse position and make sure it's within the image panel
    cPos = get(stateYao.Disp.modifyCell.axis.hdl,'CurrentPoint');
    cPos = cPos(1,1:2);
    
    % Make sure we're within image boundaries
    if all( cPos > 0 )
        cImg = get(stateYao.Disp.modifyCell.plot.hdl,'CData');
        
        if cPos(1) < size(cImg,2) && cPos(2) < size(cImg,1)
            
            if isempty( stateYao.temp.modifyCell.userSelection.data )
                % Do nothing
            else
                stateYao.temp.modifyCell.userSelection.data(end,:) =...
                    cPos;
                
                
                
                if ~isempty( stateYao.temp.modifyCell.fit.hdl )
                if ishandle( stateYao.temp.modifyCell.fit.hdl )
                    delete( stateYao.temp.modifyCell.fit.hdl )
                    delete( stateYao.temp.modifyCell.fitUnder.hdl )
                end
                end
                
                
                
                      
                x = stateYao.temp.modifyCell.userSelection.data(:,1);
                y = stateYao.temp.modifyCell.userSelection.data(:,2);
                
                max_x = 0;
                max_y = 0;
                for i = 1:size(x,1)-1
                    for j = i+1:size(x,1)
                        max_x = max([max_x abs(x(i)-x(j))]);
                        max_y = max([max_y abs(y(i)-y(j))]);
                    end
                end
                
                
                if max_x > max_y
                    if size(x,1) == 2
                        p = polyfit(x,y,1);
                    else
                        p = polyfit(x,y,2);
                    end
                    temp_x = linspace(min(x),max(x), max(x)-min(x) );
                    temp_y = polyval(p,temp_x);
                else
                    if size(y,1) == 2
                        p = polyfit(y,x,1);
                    else
                        p = polyfit(y,x,2);
                    end
                    temp_y = linspace(min(y),max(y), max(y)-min(y) );
                    temp_x = polyval(p,temp_y);
                end
                
                
                
                axes(stateYao.Disp.modifyCell.axis.hdl)
                hold on
                stateYao.temp.modifyCell.fitUnder.hdl =...
                    plot( temp_x,temp_y,'m-','LineWidth',4 );
                stateYao.temp.modifyCell.fit.hdl =...
                    plot( temp_x,temp_y,'w-','LineWidth',1 );
                hold off
                
                uistack(stateYao.temp.modifyCell.fit.hdl,'bottom')
                uistack(stateYao.temp.modifyCell.fit.hdl,'up')
                uistack(stateYao.temp.modifyCell.fitUnder.hdl,'bottom')
                uistack(stateYao.temp.modifyCell.fitUnder.hdl,'up')
                drawnow
                
                
                
                
                
                
                
                if size( stateYao.temp.modifyCell.userSelection.data ,1) > 2
                    
                    if ~isempty( stateYao.temp.modifyCell.cfit.hdl )
                    if ishandle( stateYao.temp.modifyCell.cfit.hdl )
                        delete( stateYao.temp.modifyCell.cfit.hdl )
                        delete( stateYao.temp.modifyCell.cfitUnder.hdl )
                    end
                    end
                    
                    
                    x = stateYao.temp.modifyCell.userSelection.data(1:end-1,1);
                    y = stateYao.temp.modifyCell.userSelection.data(1:end-1,2);
                    
                    max_x = 0;
                    max_y = 0;
                    for i = 1:size(x,1)-1
                        for j = i+1:size(x,1)
                            max_x = max([max_x abs(x(i)-x(j))]);
                            max_y = max([max_y abs(y(i)-y(j))]);
                        end
                    end
                    
                    
                    if max_x > max_y
                        if size(x,1) == 2
                            p = polyfit(x,y,1);
                        else
                            p = polyfit(x,y,2);
                        end
                        temp_x = linspace(min(x),max(x), max(x)-min(x) );
                        temp_y = polyval(p,temp_x);
                    else
                        if size(y,1) == 2
                            p = polyfit(y,x,1);
                        else
                            p = polyfit(y,x,2);
                        end
                        temp_y = linspace(min(y),max(y), max(y)-min(y) );
                        temp_x = polyval(p,temp_y);
                    end
                    
                    
                    
                    axes(stateYao.Disp.modifyCell.axis.hdl)
                    hold on
                    stateYao.temp.modifyCell.cfitUnder.hdl =...
                        plot( temp_x,temp_y,'b-','LineWidth',4 );
                    stateYao.temp.modifyCell.cfit.hdl =...
                        plot( temp_x,temp_y,'w-','LineWidth',1 );
                    hold off
                    
                    uistack(stateYao.temp.modifyCell.cfit.hdl,'bottom')
                    uistack(stateYao.temp.modifyCell.cfit.hdl,'up')
                    uistack(stateYao.temp.modifyCell.cfitUnder.hdl,'bottom')
                    uistack(stateYao.temp.modifyCell.cfitUnder.hdl,'up')
                    drawnow
                end
                
                
                
            end
            
        end
    end
end