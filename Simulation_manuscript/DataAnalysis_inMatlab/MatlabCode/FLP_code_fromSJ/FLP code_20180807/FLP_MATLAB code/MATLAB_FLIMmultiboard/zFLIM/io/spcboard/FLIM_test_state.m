function status = FLIM_test_state(m)
% m is module number

status=0;
[out status]=calllib('spcm32','SPC_test_state',m,status);

if(out~=0)
    display('error in FLIM_test_state');
    display(sprintf('---failed to check the status of the flimboard module %d-------',m));
end
