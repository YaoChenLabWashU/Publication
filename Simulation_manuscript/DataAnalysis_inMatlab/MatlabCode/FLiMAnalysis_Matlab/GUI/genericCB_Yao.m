function genericCB_Yao(src,eventdata)

global stateYao

if ~stateYao.Disp.mode.runningCB
% stateYao.Disp.mode.runningCB = 1;



ghLink = get(src,'Tag');



new_iImg = [];
new_numImage = [];



if any(regexp( ghLink ,'Obj3'))
    % Slider to change the position
    
    % What is the new position?
    pos = round( get(src,'Value') );
    set(src,'Value',pos)
    
    % Translate position to image number
    numImage = stateYao.CyclePositions(...
            pos,...
            stateYao.Disp.numCycle);
    
    if ~isempty(numImage)
        % Image number found
        
        new_iImg = pos;
        new_numImage = numImage;
    else
        % Reset
        new_iImg = stateYao.Disp.iImg;
        new_numImage = stateYao.CyclePositions(...
            stateYao.Disp.iImg,...
            stateYao.Disp.numCycle);
    end
    
    
    
elseif any(regexp( ghLink ,'Obj2'))
    % Edit to indicate/change position
    
    
    
    % What is the new position?
    newVal = str2num( get(src,'String') );
    
    if isempty(newVal)
        % Not a valid entry!
        %   Reset
        new_iImg = stateYao.Disp.iImg;
        new_numImage = stateYao.CyclePositions(...
            stateYao.Disp.iImg,...
            stateYao.Disp.numCycle);
        
    else
        % Entry is a number. Is that number within the image #s for this cycle?
        newVal = round(newVal);
        
        
        imageList = abs(...
            stateYao.CyclePositions(:,stateYao.Disp.numCycle)-...
            newVal);
        [min_val min_idx] = min(imageList);
        
        new_iImg = min_idx;
        new_numImage = stateYao.CyclePositions(new_iImg,stateYao.Disp.numCycle);
        
    end
    
    
    
elseif any(regexp( ghLink ,'Obj1'))
    % Changing cycle position
    
    global ghYao
    
    
    hdl = eval(sprintf('%s.hdl',ghLink));
    
    optList = get(hdl,'String');
    optVal = get(hdl,'Value');
    
    
    
    stateYao.Disp.numCycle = str2num( optList{optVal} );
    
    
    
    new_iImg = 1;
    new_numImage = stateYao.CyclePositions(...
            new_iImg,...
            stateYao.Disp.numCycle);
    
    
    
    stateYao.Disp.ROI.userSelection.data = [];
    stateYao.Disp.ROI.ellipse.data = [];
    
    
    
elseif any(regexp( ghLink ,'Obj4'))
    
    Yao_GUI_Quit_v2
    
    
    
    
    
    
    
elseif any(regexp( ghLink ,'Obj7'))
    % ReCalc Mask
    numCycle = stateYao.Disp.numCycle;
    iImg = stateYao.Disp.iImg;
    
    
    cellID = get(src,'UserData');
    
    
%     
%     
%     idx = regexp( ghLink ,'[.]');
%     temp = ghLink( idx(end)+1:end);
%     
%     idx_Obj = regexp(temp,'Obj');
%     temp = temp( size('Ellipse',2)+1 : idx_Obj -1 );
%     
%     iEllipse = str2num(temp);
%     
%     
%     
%     
%     cellIdList = stateYao.cellIdx{iCycle}{iImg}(:,2);
%     cellIdList = sortrows(cellIdList);
%     for iCellId = size(cellIdList,1):-1:1
%         idxCell = stateYao.cellIdx{iCycle}{iImg}(iCellId,1);
%         
%         if all(stateYao.ellipseParameters{iCycle}{iImg}(idxCell,:)==0)
%             cellIdList(iCellId) = [];
%         end
%     end
%     
%     cellID = cellIdList(iEllipse);
% 
%     
%     
    Yao_findNucleusMask_ReCalc_v3(numCycle,iImg,cellID)
    
    
    
elseif any(regexp( ghLink ,'nucleusSearch'))
    % First 3 options are not functional
    
    numCycle = stateYao.Disp.numCycle;
    iImg = stateYao.Disp.iImg;
    
    
    
    cellID = get(src,'UserData');
    
%     idx = regexp( ghLink ,'[.]');
%     temp = ghLink( idx(end)+1:end);
%     
%     idx_Obj = regexp(temp,'Cell');
%     temp = temp(idx_Obj+size('Cell',2):end);
%     
%     iEllipse = str2num(temp);
%     
%     
%     
%     cellIdList = stateYao.cellIdx{iCycle}{iImg}(:,2);
%     cellIdList = sortrows(cellIdList);
%     for iCellId = size(cellIdList,1):-1:1
%         idxCell = stateYao.cellIdx{iCycle}{iImg}(iCellId,1);
%         
%         if all(stateYao.ellipseParameters{iCycle}{iImg}(idxCell,:)==0)
%             cellIdList(iCellId) = [];
%         end
%     end
%     
%     cellIdList
%     iEllipse
%     
%     cellID = cellIdList(iEllipse);
    idxCell = stateYao.cellIdx{numCycle}{iImg}(...
        stateYao.cellIdx{numCycle}{iImg}(:,2)==cellID ,1);
    
    
    
    
    curFunc = stateYao.funcLink.findNucleus_func{numCycle}{iImg}{idxCell};
    
    if get(src,'Value')  > 3
    
    newFunc = get( src ,'String');
    newFunc = newFunc{ get(src,'Value') };
    
    if ~strcmp( curFunc, newFunc )
        
        stateYao.funcLink.findNucleus_func{numCycle}{iImg}{idxCell} = newFunc;
        
        fprintf('%s: Finding new nucleus with\n\t%s\n',...
            mfilename,newFunc)
        eval( sprintf('%s(numCycle,iImg,cellID)',...
            stateYao.funcLink.findNucleus) )
        fprintf('\t\tDone\n')
        
        
        
        Yao_GUI_loadImage
        
    end
    else
    optList = get( src ,'String');
    for iOpt = 1:size(optList,1)
        if strcmp(curFunc,optList{iOpt})
            set(src,'Value',iOpt)
            break
        end
    end
    end % if get(src,'Value') > 3
    
    
    
    
elseif any(regexp( ghLink ,'colorNucleus'))
    
    numCycle = stateYao.Disp.numCycle;
    iImg = stateYao.Disp.iImg;
    
    cellID = get(src,'UserData');
    
    
    
    idxCell = stateYao.cellIdx{numCycle}{iImg}(...
        stateYao.cellIdx{numCycle}{iImg}(:,2)==cellID ,1);
    
    
    
    curColor = stateYao.colorNucleus{numCycle}{iImg}{idxCell};
    
    newColor = get( src ,'String');
    newColor = newColor{ get(src,'Value') };
    
    
    
    if ~strcmp( curColor, newColor )
        if strcmp(...
                stateYao.funcLink.findNucleus_func{numCycle}{iImg}{idxCell},...
                'None') || strcmp(...
                stateYao.funcLink.findNucleus_func{numCycle}{iImg}{idxCell},...
                'User Input') || strcmp(...
                stateYao.funcLink.findNucleus_func{numCycle}{iImg}{idxCell},...
                'Mask')
            
            stateYao.funcLink.findNucleus_func{numCycle}{iImg}{idxCell} =...
                stateYao.funcLink.findNucleus_func_default;
        end
        
        
        stateYao.colorNucleus{numCycle}{iImg}{idxCell} = newColor;
        
        fprintf('%s: Finding new nucleus with\n\t%s\n',...
            mfilename,newColor)
        eval( sprintf('%s(numCycle,iImg,cellID)',...
            stateYao.funcLink.findNucleus) )
        fprintf('\t\tDone\n')
        
        
        
        Yao_GUI_loadImage
        
    end
    
    
    
    
elseif any(regexp( ghLink ,'ApplyChangeTo'))
    
    numCycle = stateYao.Disp.numCycle;
    iImg = stateYao.Disp.iImg;
    
    cellID = get(src,'UserData');
    
    
    
    % Apply to all images? Just proceeding images? Just preceeding images?
    qAnswer = questdlg('Apply to which images?',...
        'Apply Change To',...
        'All','Images After','Images Before','All');
    
    iImgList = [];
    getMask = 0;
    switch qAnswer
        case 'All',
            iImgList = 1:size( stateYao.CyclePositions ,1);
            getMask = 1;
        case 'Images After',
            if iImg ~= size( stateYao.CyclePositions ,1)
                iImgList = iImg+1:size( stateYao.CyclePositions ,1);
            end
        case 'Images Before',
            if iImg ~= 1
                iImgList = 1:iImg-1;
            end
    end
    
    % Are there any images left?
    if ~isempty(iImgList)
        fprintf('Searching for appropriate images to process...\n')
        % Make sure that 
        %   we are not repeating the current iImg
        %   CyclePositions ~= 0
        %   ignoreImage == 0
        %   It has the cell!
        
        for i_iImgList = length(iImgList):-1:1
            iImg2 = iImgList(i_iImgList);
            
            if iImg2 == iImg ||...
                    stateYao.CyclePositions(iImg2,numCycle) == 0 ||...
                    stateYao.ignoreImage(iImg2,numCycle) ~= 0 ||...
                    ~any( stateYao.cellIdx{numCycle}{iImg2}(:,2) == cellID )
                iImgList(i_iImgList) = [];
            end
        end
        
        
        
        % Are there any images left?
        if isempty(iImgList)
            fprintf('\tNo appropriate images found\n')
        else
            % Yes!
            %   What function and colorNucleus are we using?
            idxCell = 1:size(stateYao.cellIdx{numCycle}{iImg},1);
            idxCell = idxCell(...
                stateYao.cellIdx{numCycle}{iImg}(:,2) == cellID );
            idxCell = stateYao.cellIdx{numCycle}{iImg}(idxCell,1);
            
            findNucleus_func = ...
                stateYao.funcLink.findNucleus_func{numCycle}{iImg}{idxCell};
            if strcmp(...
                    findNucleus_func,...
                    'None') || strcmp(...
                    findNucleus_func,...
                    'User Input') || strcmp(...
                    findNucleus_func,...
                    'Mask')
                
                findNucleus_func =...
                    stateYao.funcLink.findNucleus_func_default;
                
                iImgList(end+1) = iImg;
            end
            
            colorNucleus =...
                stateYao.colorNucleus{numCycle}{iImg}{idxCell};
            
            
            
            str = sprintf('Finding Nuclei for Cycle %d...',numCycle);
            hdlProgFindNucleus = waitbar(0,str);
            for i_iImgList = 1:length(iImgList)
                iImg2 = iImgList(i_iImgList);
                
                if ishandle(hdlProgFindNucleus)
                waitbar(...
                    i_iImgList/length(iImgList),...
                    hdlProgFindNucleus)
                drawnow
                end
                
                
                
                idxCell = 1:size(stateYao.cellIdx{numCycle}{iImg2},1);
                idxCell = idxCell(...
                    stateYao.cellIdx{numCycle}{iImg2}(:,2) == cellID );
                idxCell = stateYao.cellIdx{numCycle}{iImg2}(idxCell,1);
                
                stateYao.funcLink.findNucleus_func{numCycle}{iImg2}{idxCell} =...
                    findNucleus_func;
                stateYao.colorNucleus{numCycle}{iImg2}{idxCell} =...
                    colorNucleus;
                
                
                
                eval( sprintf('%s(numCycle,iImg2,cellID)',...
                    stateYao.funcLink.findNucleus) )
            end
            if ishandle(hdlProgFindNucleus)
            close(hdlProgFindNucleus)
            drawnow
            end
            
            
            
            fprintf('\tGetting mask...\n')
            eval(sprintf('%s(%s)',...
                stateYao.funcLink.findNucleusMask,...
                sprintf('%s,%s,%s',...
                'numCycle','iImgList','cellID') ))
            
            
        end
    end
    
    fprintf('\t Done\n')
    
    Yao_GUI_loadImage
    
    
else
    ghLink
    
end






%%
if ~isempty(new_iImg) || ~isempty(new_numImage)
    
% % % %     if stateYao.ignoreImage(new_iImg,stateYao.numCycle(stateYao.Disp.iCycle))
% % % %         if any( ~stateYao.ignoreImage(:,stateYao.numCycle(stateYao.Disp.iCycle)) )
% % %         % New new image
% % %         
% % %         temp = stateYao.CyclePositions(:,stateYao.numCycle(stateYao.Disp.iCycle));
% % %         temp = cat(2,temp,[1:size(stateYao.CyclePositions,1)]');
% % % %         temp = cat(2,temp,stateYao.ignoreImage(:,stateYao.numCycle(stateYao.Disp.iCycle)));
% % %         temp = temp( temp(:,1)~=0 ,:);
% % % %         temp = temp( temp(:,3)==0 ,:);
% % %         
% % %         
% % %         if ~any( temp(:,2) == new_iImg ) || ~any( temp(:,1) == new_numImage )
% % % 
% % %         if new_iImg == stateYao.Disp.iImg
% % %             % Can we move forward one index?
% % %             if new_iImg < temp(end,2)
% % %                 % Yes
% % %                 temp2 = temp(:,2) > new_iImg;
% % %                 [max_val max_idx] = max(temp2);
% % %                 
% % %                 new_iImg = temp(max_idx,2);
% % %                 dataIn = [stateYao.numCycle(stateYao.Disp.iCycle) new_iImg];
% % %                 [new_numImage] = Yao_generic_convertImgID(dataIn);
% % %             else
% % %                 % No
% % %                 % Can we move back?
% % %                 if new_iImg > temp(1,2)
% % %                     % Yes
% % %                     temp2 = temp(:,2) < new_iImg;
% % %                     temp2 = temp2( end:-1:1 );
% % %                     [max_val max_idx] = max(temp2);
% % %                     max_idx = size(temp2,1) - max_idx +1;
% % %                     
% % %                     new_iImg = temp(max_idx,2);
% % %                     dataIn = [stateYao.numCycle(stateYao.Disp.iCycle) new_iImg];
% % %                     [new_numImage] = Yao_generic_convertImgID(dataIn);
% % %                 else
% % %                     % No
% % %                     new_iImg = temp(1,2);
% % %                     dataIn = [stateYao.numCycle(stateYao.Disp.iCycle) new_iImg];
% % %                     [new_numImage] = Yao_generic_convertImgID(dataIn);
% % %                 end
% % %             end
% % %             
% % %             
% % %         else
% % %             % Which direction is the user moving?
% % %             if new_iImg > stateYao.Disp.iImg
% % %                 % Can we move forward?
% % %                 if new_iImg < temp(end,2)
% % %                     % Yes
% % %                     temp2 = temp(:,2) > new_iImg;
% % %                     [max_val max_idx] = max(temp2);
% % %                     
% % %                     new_iImg = temp(max_idx,2);
% % %                     dataIn = [stateYao.numCycle(stateYao.Disp.iCycle) new_iImg];
% % %                     [new_numImage] = Yao_generic_convertImgID(dataIn);
% % %                 else
% % %                     % No
% % %                     new_iImg = temp(1,2);
% % %                     dataIn = [stateYao.numCycle(stateYao.Disp.iCycle) new_iImg];
% % %                     [new_numImage] = Yao_generic_convertImgID(dataIn);
% % %                 end
% % %             else
% % %                 % Can we move back?
% % %                 if new_iImg > temp(1,2)
% % %                     % Yes
% % %                     temp2 = temp(:,2) < new_iImg;
% % %                     temp2 = temp2( end:-1:1 );
% % %                     [max_val max_idx] = max(temp2);
% % %                     max_idx = size(temp2,1) - max_idx +1;
% % %                     
% % %                     new_iImg = temp(max_idx,2);
% % %                     dataIn = [stateYao.numCycle(stateYao.Disp.iCycle) new_iImg];
% % %                     [new_numImage] = Yao_generic_convertImgID(dataIn);
% % %                 else
% % %                     % No
% % %                     new_iImg = temp(1,2);
% % %                     dataIn = [stateYao.numCycle(stateYao.Disp.iCycle) new_iImg];
% % %                     [new_numImage] = Yao_generic_convertImgID(dataIn);
% % %                 end
% % %             end
% % %         end
% % %         
% % %         
% % %         end
% % %         
% % % %         end
% % % %     end
    numCycle = stateYao.Disp.numCycle;
        
    temp = stateYao.CyclePositions(:,numCycle);
    temp = cat(2,temp,[1:size(stateYao.CyclePositions,1)]');
    %         temp = cat(2,temp,stateYao.ignoreImage(:,stateYao.numCycle(iCycle)));
    temp = temp( temp(:,1)~=0 ,:);
    %         temp = temp( temp(:,3)==0 ,:);
    
    if ~any( temp(:,2) == new_iImg )
        
        
        % Which direction is the user moving?
        if new_iImg > stateYao.Disp.iImg
            % Can we move forward?
            if new_iImg < temp(end,2)
                % Yes
                temp2 = temp(:,2) > new_iImg;
                [max_val max_idx] = max(temp2);
                
                new_iImg = temp(max_idx,2);
            else
                % No
                new_iImg = temp(1,2);
            end
        else
            % Can we move back?
            if new_iImg > temp(1,2)
                % Yes
                temp2 = temp(:,2) < new_iImg;
                temp2 = temp2( end:-1:1 );
                [max_val max_idx] = max(temp2);
                max_idx = size(temp2,1) - max_idx +1;
                
                new_iImg = temp(max_idx,2);
            elseif new_iImg == temp(1,2)
                new_iImg = temp(1,2);
            else
                new_iImg = temp(end,2);
            end
        end
        
        
    end
    
    new_numImage = stateYao.CyclePositions(...
        new_iImg,...
        numCycle);


    
%     stateYao.Disp.cCell = 1;
    
    
    stateYao.Disp.iImg = new_iImg;
    
    set( stateYao.Disp.Position.Slider.hdl ,...
        'Value',new_iImg)
    set( stateYao.Disp.Position.Edit.hdl ,...
        'String',num2str( new_numImage ) )
    
    Yao_GUI_loadImage
end



stateYao.Disp.mode.runningCB = 0;
end



end