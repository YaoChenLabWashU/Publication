

global spc gui ROIPosMatrix


%%
% Get the current group information

% filepath=gui.gy.filename.path;
% basename=gui.gy.filename.base;
filepath = 'W:\Yao\microscopy\FLIM\AfterMovingToWAB\Analyzed\acuteHipo_PKI_mus\control\ycAKAR706(acuteHippo_Cre+AKAR6_mus)-Analyze\';
basename = 'ycAKAR706';
filename=sprintf('%s\\%sFLIM.xlsx',filepath,basename);
[num, txt, raw]=xlsread(filename, 1, 'A:A');
clear num txt




%%
% Go through RAW excel data to find which images we are interested in
%   Open respective hdr file to identify cycle position
%       Save cycle position information
indexbeginning=[]; indexend=[];PositionMatrix=[];
for irow=1:size(raw,1)
    entry=raw{irow,1}; % {} gives you the characters inside the cell.
    if ischar(entry)
        if any(regexp(entry, basename))
            indexbasename=regexp(entry,basename);
            entrynumberSTR=...
                entry(indexbasename(end)+size(basename,2)+size('FLIM',2):...
                end-size('.mat',2));
            entrynumber=str2num(entrynumberSTR);
            if isempty(indexbeginning)
                indexbeginning=entrynumber;
                indexend=entrynumber;
            else
                indexbeginning=min([indexbeginning entrynumber]);
                indexend=max([indexbeginning entrynumber]);
            end
            
            
            
            % Get cycle position from hdr file
            newName = sprintf('%s%s%s%s',...
                filepath,...
                basename,...
                entrynumberSTR,...
                '_hdr.txt');
            CyclePosition=str2double(GrabCyclePosition(newName));
            if isempty(PositionMatrix)
                PositionMatrix(1,CyclePosition)=entrynumber;
                
            elseif size(PositionMatrix,2) < CyclePosition
                temp_PositionMatrix = PositionMatrix;
                PositionMatrix = zeros( size(temp_PositionMatrix,1),CyclePosition);
                PositionMatrix(1:size(temp_PositionMatrix,1),1:size(temp_PositionMatrix,2))=...
                    temp_PositionMatrix;
                PositionMatrix(1,CyclePosition) = entrynumber;
                clear temp_PositionMatrix
                
            else
                if PositionMatrix(end,CyclePosition)==0
                    [min_val min_idx] = min(PositionMatrix(:,CyclePosition));
                    PositionMatrix(min_idx,CyclePosition)=entrynumber;
                    clear min_val min_idx
                else
                    PositionMatrix(end+1,CyclePosition)=entrynumber;
                end
            end
            
        end
    end
end
clear irow entry indexbasename entrynumberSTR entrynumber
clear newName CyclePosition

% Not all file information may have been recorded
for number=indexbeginning:indexend
    if ~any(any(PositionMatrix==number))
        if number<10
            entrynumberSTR=sprintf('00%d', number);
        elseif number<100
            entrynumberSTR=sprintf('0%d', number);
        else
            entrynumberSTR=num2str(number);
        end
        newName = sprintf('%s%s%s%s',...
            filepath,...
            basename,...
            entrynumberSTR,...
            '_hdr.txt');
        
        if exist(newName,'file')
            CyclePosition=str2double(GrabCyclePosition(newName));
            if PositionMatrix(end,CyclePosition)==0
                [min_val min_idx] = min(PositionMatrix(:,CyclePosition));
                PositionMatrix(min_idx,CyclePosition)=number;
                clear min_val min_idx
            else
                PositionMatrix(end+1,CyclePosition)=number;
            end
            clear CyclePosition
        end
        
    end
end
clear number indexbeginning indexend entrynumberSTR newName



%
% for iCycle = 1:size(PositionMatrix,2)
for iCycle = 1
%     for iImg = 1:size(PositionMatrix,1)
    for iImg = 1
        number = PositionMatrix(iImg,iCycle);
        
        
        
        if number<10
            entrynumberSTR=sprintf('00%d', number);
        elseif number<100
            entrynumberSTR=sprintf('0%d', number);
        else
            entrynumberSTR=num2str(number);
        end
        
        
        
        newName = sprintf('%s%s%s%s%s',...
            filepath,...
            basename,...
            'FLIM',...
            entrynumberSTR,...
            '.mat');
        
        matobj = matfile( newName );
        spcSave = matobj.spcSave;
        
    end
end


%         spc.nROIs=size(gui.gy.roiPositions,2);
%         spc.CyclePosition=str2double(GrabCyclePosition(spc.HeaderFile)); 




% spc_openFiles(15,[])




