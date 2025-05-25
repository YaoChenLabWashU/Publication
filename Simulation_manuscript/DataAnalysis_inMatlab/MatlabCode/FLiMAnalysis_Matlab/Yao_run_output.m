% function Yao_run_output(CyclePosition)

global gui stateYao CyclePosition
if nargin<1
    CyclePosition=0;
end

handles=guihandles(gui.spc.spc_main.spc_main);




if CyclePosition>0
    for iImg=1:size(stateYao.CyclePositions(:,CyclePosition),1) %we will go through these many files
        % Open the correct file based on cycle position
        numImage=stateYao.CyclePositions(iImg,CyclePosition);
        
        if numImage > 0
        
        % Tell spc_main to load new image
        spc_openFiles(numImage,[])
        
        % What is the ROI based on Yao_run_shift results?
        ROIPosition=stateYao.ROI{iImg}; %will need to store this based on multiple cycle positions.
        
        % Apply changes
        for roi = 1
            for type=1:2
                setPosition(gui.gy.rois{1,roi}.obj{1,type}, ROIPosition)
                spc_conformROIpositions;
            end
        end
        clear roi type
        
        % Fit, write data to excel, write data to wave
        for fc=FLIMchannels
            if ~bitget(state.spc.FLIMchoices(fc),3) % avoid calc'ed channels
                if isfield(spc.fits{fc},'lastFitFunction')
                    % use the last fit function automatically
                    fh=str2func(spc.fits{fc}.lastFitFunction);
                    fh(fc);
                else spc_fitexp2gaussGY(fc);
                end
%                 if fc==spc_mainChannelChoice
%                     fitMenuChecks(handles,fc);
%                 end
            end
        end
        
        spc_SaveFitToExcel
        
        
        end
        
        
    end
end
% end

% else % go until the end of the files with this name
%     stillNew=1;
%     while stillNew
%         filenum=str2double(get(handles.File_N, 'String'));
%         spc_main('toExcelAndAdvance_Callback',[],[],handles);
%         newfile=str2double(get(handles.File_N, 'String'));
%         stillNew=filenum~=newfile;
%     end
% 

        
