function Yao_generic_getCyclePositions_v2(spc,gui)

% Have we already found all the images tied to each cycle position?
global stateYao
global redefine Epochstart Epochend redefineAcq

findCyclePositions = 0;
if isempty(stateYao)
    findCyclePositions = 1;
elseif ~isfield(stateYao,'baseName')
    findCyclePositions = 1;
else
    % Get current baseName, compare to stateYao.baseName
    fileName = spc.filename;
    
    idxSlash = regexp(fileName,'\');
    idxFLIM = regexp(fileName,'FLIM');
    baseName = fileName( idxSlash(end)+1: idxFLIM(end)-1 );
    clear idxSlash idxFLIM fileName
    
    
    
    if ~strcmp(stateYao.baseName,baseName) % Compare strings with case sensitivity
        findCyclePositions = 1;
    end
    clear baseName

end



if findCyclePositions
    clear findCyclePositions
    
    
    
    filepath=gui.gy.filename.path;
    basename=gui.gy.filename.base;
    filename=sprintf('%s%sFLIM.xlsx',filepath,basename); % removed FLIM behind second %s. 5/19/2016 YC
    [num, txt, raw]=xlsread(filename, 1, 'A:A');
    clear num txt
    
    
    stateYao.baseName = basename;
    
    
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

                if redefine ==3
                    if entrynumber>=redefineAcq
                        if CyclePosition == 2
                            CyclePosition = 3;
                        elseif CyclePosition ==3
                            CyclePosition = 5;
                        end
                    end
                end


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
            newName_hdr = sprintf('%s%s%s%s',...
                filepath,...
                basename,...
                entrynumberSTR,...
                '_hdr.txt');
            
            if exist(newName_hdr,'file')
                newName_image_tif = sprintf('%s%s%s%s',...
                    filepath,...
                    basename,...
                    entrynumberSTR,...
                    '.tif');
                newName_image_tiff = sprintf('%s%s%s%s',...
                    filepath,...
                    basename,...
                    entrynumberSTR,...
                    '.tiff');
                if exist(newName_image_tif,'file') ||...
                        exist(newName_image_tiff,'file')
                
                CyclePosition=str2double(GrabCyclePosition(newName_hdr));
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
    end
    clear number indexbeginning indexend entrynumberSTR newName
    
    
    
    % Sort
    for iCycle = 1:size(PositionMatrix,2)
        temp = PositionMatrix(:,iCycle);
        temp = temp( temp~=0 );
        temp = sortrows( temp ,1);
        PositionMatrix( 1:size(temp,1) ,iCycle) = temp;
    end
    
    
    
    stateYao.CyclePositions = PositionMatrix;
    clear PositionMatrix
end


end