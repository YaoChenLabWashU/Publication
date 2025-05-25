

global spc gui ROIPosMatrix


% filepath=gui.gy.filename.path;
% basename=gui.gy.filename.base;
% filename=sprintf('%s\\%sFLIM.xlsx',filepath,basename);
% [num, txt, raw]=xlsread(filename, 1, 'A:A');
% clear num txt

filename=sprintf('%s\\%sFLIM',filepath,basename);
indexbeginning=[]; indexend=[];PositionMatrix=[];
for irow=1:size(raw,1)
    entry=raw{irow,1}; % {} gives you the characters inside the cell.
    if ischar(entry)
        if any(regexp(entry, basename))
            indexbasename=regexp(entry,basename);
            entrynumberSTR=entry(indexbasename(end)+size(basename,2)+size('FLIM',2):end-size('.mat',2));
            entrynumber=str2num(entrynumberSTR);
            if isempty(indexbeginning)
                indexbeginning=entrynumber;
                indexend=entrynumber;
            else
                indexbeginning=min([indexbeginning entrynumber]);
                indexend=max([indexbeginning entrynumber]);
            end
            
            
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
                    PositionMatrix(end,CyclePosition)=entrynumber;
                else
                    PositionMatrix(end+1,CyclePosition)=entrynumber;
                end
            end
        end
    end
end

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
                    PositionMatrix(end,CyclePosition)=number;
                else
                    PositionMatrix(end+1,CyclePosition)=number;
            end
        end
    end
end
% may want to find the last "zero" rather than the end.
    
%         spc.nROIs=size(gui.gy.roiPositions,2);
%         spc.CyclePosition=str2double(GrabCyclePosition(spc.HeaderFile)); 









