function pzCal(pos)

global state
if(pos>100)
    disp('Piezo out of range');
    return
end

if(pos<0)
    disp('Piezo out of range');
    return
end

state.piezo.last_pos=pos;