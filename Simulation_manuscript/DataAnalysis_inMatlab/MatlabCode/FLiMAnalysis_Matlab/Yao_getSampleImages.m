function Yao_getSampleImages(samplepath)

% Get Sample Images and save stateYao

global stateYao



for numCycle = stateYao.processCycles'
    if ~isnumeric(stateYao.CycleIdentification{numCycle,2})
        
        % How many cells are there?
        nCell = 0;
        for iImg = 1:size(stateYao.CyclePositions,1)
            if stateYao.CyclePositions(iImg,numCycle) ~= 0
                if stateYao.ignoreImage(iImg,numCycle) == 0
                    nCell = max([nCell size(stateYao.images.I_cell_stack{numCycle}{iImg},3)]);
                end
            end
        end
        
        
        
        % Find image that has all cells
        foundImage = 0;
        foundImage_iImg = [];
        
        for iImg = 1:size(stateYao.CyclePositions,1)
        if stateYao.CyclePositions(iImg,numCycle) ~= 0
        if stateYao.ignoreImage(iImg,numCycle) == 0
            
            if size( stateYao.applyMask{numCycle}{iImg} ,1) == nCell
                if ~any( stateYao.applyMask{numCycle}{iImg} )
                    foundImage = 1;
                    foundImage_iImg = iImg;
                    break
                end
            end
            
        end
        end
        end
        
        if ~foundImage
        for iImg = 1:size(stateYao.CyclePositions,1)
        if stateYao.CyclePositions(iImg,numCycle) ~= 0
        if stateYao.ignoreImage(iImg,numCycle) == 0
            
            if size( stateYao.images.I_cell_stack{numCycle}{iImg} ,3) == nCell &&...
                    size( stateYao.cellIdx{numCycle}{iImg} ,1) == nCell
                foundImage = 1;
                foundImage_iImg = iImg;
                break
            end
            
        end
        end
        end
        end
        
        
        
        if ~foundImage
            fprintf('%s: Unable to find appropriate sample image for cycle %d\n',...
                mfilename,numCycle)
        else
            img = stateYao.images.origData.rgbLifetimes{numCycle}(:,:,:,foundImage_iImg);
            
            
            h_fig = figure;
            h_img = imshow(img);
            
            
            h_text = zeros( size( stateYao.cellIdx{numCycle}{foundImage_iImg} ,1) ,1);
            h_textUnder = zeros( size( stateYao.cellIdx{numCycle}{foundImage_iImg} ,1) ,4);
            underShiftMatrix = [0 0.5;0 -0.5;0.5 0; -0.5 0];
            for iCell = 1:size( stateYao.cellIdx{numCycle}{foundImage_iImg} ,1)
                idxCell = stateYao.cellIdx{numCycle}{foundImage_iImg}(iCell,1);
                iCell_true = stateYao.cellIdx{numCycle}{foundImage_iImg}(iCell,2);
                x0 = stateYao.cellIdx{numCycle}{foundImage_iImg}(iCell,5);
                y0 = stateYao.cellIdx{numCycle}{foundImage_iImg}(iCell,6);
                
                
                
                for iUnder = 1:4
                h_textUnder(iCell,iUnder) = text(...
                    x0+underShiftMatrix(iUnder,1),...
                    y0+underShiftMatrix(iUnder,2),...
                    sprintf('%d',iCell_true) ,...
                    'HorizontalAlignment','center',...
                    'Color','w',...
                    'FontWeight','bold' );
                end
                
                h_text(iCell) = text( x0,y0,...
                    sprintf('%d',iCell_true) ,...
                    'HorizontalAlignment','center',...
                    'Color','m',...
                    'FontWeight','bold');
                
                
                
            end
            
            
            newSize = 300;
            
            truesize(h_fig,[newSize newSize])
            for iCell = 1:size(h_text,1)
                for iUnder = 1:4
                set(h_textUnder(iCell,iUnder),'FontSize',...
                    get(h_textUnder(iCell,iUnder),'FontSize')*newSize/size(img,1) )
                end
                
                set(h_text(iCell),'FontSize',...
                    get(h_text(iCell),'FontSize')*newSize/size(img,1) )
                
            end
            
            
            
%             global gui
%             
%             savePath = sprintf('%s%s%s.png',...
%                 gui.gy.filename.path,...
%                 stateYao.baseName,...
%                 sprintf('_Cycle%d',numCycle) );
            savePath = sprintf('%s%s%s.png',...
                samplepath,...
                stateYao.baseName,...
                sprintf('_Cycle%d',numCycle) );



            
            saveas(h_fig,savePath)
            
            
            fprintf('%s: Saved sample image for Cycle %d to \n\t%s\n\n',...
                mfilename,numCycle,savePath)
            
            
            close(h_fig)
            
        end
        
        
    end
end

%save stateYao
AnalysisDate=datestr(clock,29);
saveFileName=sprintf('%s%s_Analysis%s.mat',...
    samplepath,...
    stateYao.baseName,...
    AnalysisDate);
save(saveFileName, 'stateYao')