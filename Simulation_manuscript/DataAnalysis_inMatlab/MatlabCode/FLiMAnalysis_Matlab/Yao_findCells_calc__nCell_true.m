function [nCell_true] = Yao_findCells_calc__nCell_true(nCellList)


if mean(nCellList( nCellList(:,2)~=0 ,2)) -...
        floor( mean(nCellList( nCellList(:,2)~=0 ,2)) ) < 0.25
    nCell_true = floor( mean(nCellList( nCellList(:,2)~=0 ,2)) );
else
    nCell_true = ceil( mean(nCellList( nCellList(:,2)~=0 ,2)) );
end



if ~any( nCellList(:,2) == nCell_true )
    % No image has the "correct" number of cells
    %   Usually happens with over-zealous valley detection
    if any( nCellList(:,2) == nCell_true-1 )
        nCell_true = nCell_true-1;
    elseif any( nCellList(:,2) == nCell_true+1 )
        nCell_true = nCell_true-1;
    else
        nCell_true = median( nCellList( nCellList(:,2)~=0 ,2) );
    end
end