function gaptime = FLIM_ReadGapTime(m)
% SJ 2016/11
% Gap time (in ms) calcuation for the data aquisition with sequencer
% Reading the gap time between the beginning of the next memory bank
% measurement and the end of the data read out/clearing of the previous
% memory bank
% Normally, the data readout and the bank clearing should be accomplished 
% in a time shorter than the overall measurement time for one memory bank. 
% If the end of the alternate bank is reached by the measurement before a 
% new start command has been issued, the measurement stops until the start 
% command is received. 

gaptime=0;
[out gaptime]=calllib('spcm32','SPC_read_gap_time',m,gaptime);

if(out~=0)
    display('error in FLIM_test_state');
    display(sprintf('---failed to read the gaptime of the flimboard module %d-------',m));
end

end

