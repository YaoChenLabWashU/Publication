function [] = zFLP_DoAll()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
global state spc
global FLPdata_time FLPdata_lifetimes FLPdata_fits FLPdata_counter;
global FLIMchannels

% state.FLP.totalAcqTime=20;
% state.FLP.sliceTime=0.005;
% state.FLP.sequencer=1;

% state.FLP.totalAcqTime=1;
% state.FLP.sliceTime=0.1;
% state.FLP.sequencer=0;

state.FLP.totalAcqTime=state.cycle.totalAcqTime;
state.FLP.sliceTime=state.cycle.sliceTime;
state.FLP.sequencer=state.cycle.sequencer;

try
    close('Real time lifetime plot');
catch
end
h=figure('Name','Real time lifetime plot','NumberTitle','off');
figure(h);
xlabel('time(s)');
ylabel('tau(s)');
hold on;

display('zFLP_DoAll....');
timerFirstSetup_zFLP;
timerSetup_zFLP;

FLPdata_time=[]; FLPdata_lifetimes=[]; FLPdata_fits=[];
if state.cycle.syncPhys==1 %when zFLP is slaved to the physiology
elseif state.FLP.sequencer==1 %continuous aquistion mode using sequencer (data reading interval is determined by the memory filling time for one memory bank)
    for m=state.spc.acq.modulesInUse
        FLIM_StopMeasurement(m);  
        state.spc.acq.SPCdata{m+1}.mem_bank=0;
        FLIM_setParameters(m);
        FLIM_enable_sequencer(m,2); %turn on sequncer. while for ‘enable’ = 2, the function arms SPC only for current memory bank.
        FLIM_ConfigureMemory(m);
        FLIM_FillMemory(m,-1);  %clear current memory bank, -1 is for all pages
        state.spc.acq.SPCdata{m+1}.mem_bank=1;
        FLIM_setParameters(m);
        FLIM_FillMemory(m,-1);  %clear current memory bank, -1 is for all pages
    end
    
    spc.imageMod = [];  % clear these to start
    spc.lifetime=[];
    spc.project=[];
    spc.errCode=999;
    acqTime=0; FLPdata_counter=0;
    flag=0;
    maxpage=state.spc.acq.SPCMemConfig{m+1}.maxpage;
    display('sequencer is on');
    display(['data reading time interval (s): ',num2str(maxpage*state.FLP.sliceTime)]);
    
    startTime=clock;
    while(acqTime < state.FLP.totalAcqTime)
        if state.timer.abort==1
            display('-------FLP data collection aborted');
            break;
        end
        
        for m=state.spc.acq.modulesInUse
            FLIM_StartMeasurement(m); %start measurement for the current memory bank
        end
        
        %%%%%%
        display('call timerfunction now');
        return
        
        if(flag==1) %wait until the first memory bank is filled
            acqTime=etime(clock, startTime);
            spc_readPageFLP_sequencer(acqTime); %read the disarmed memory bank
            FLIM_FillMemory(m,-1);  %clear the memory bank that was just read, -1 is for all pages
            gapTime=FLIM_ReadGapTime(1);
            
            if(FLPdata_counter==maxpage) %if this is the first slice
                timerProcess_zFLP; %initialize spc construct for fitting purpose
            end
            
            %fitting the exponential curve to each lifetime curves from this data reading session
            for ch=FLIMchannels
                for i=FLPdata_counter-maxpage+1:10:FLPdata_counter %fit every 10 lifetime curves to reduce operation time
                    spc.lifetimes{ch}=FLPdata_lifetimes{i,ch};
                    %spc_fitexp2gaussGY_noplot(ch);
                    spc_fitexpgaussGY(ch);
                    FLPdata_fits{i,ch}=spc.fits{ch};
                    figure(h);
                    plot(FLPdata_time(i,ch),FLPdata_fits{i,ch}.beta2,'.');
                end
            end
                
            %fitting the exponential curve only to the last slice of the read data
%             for ch=FLIMchannels
%                 spc.lifetimes{ch}=FLPdata_lifetimes{FLPdata_counter,ch};
%                 %spc_fitexp2gaussGY_noplot(ch);
%                 spc_fitexpgaussGY_noplot(ch);
%                 FLPdata_fits{FLPdata_counter,ch}=spc.fits{ch};
%                 figure(h);
%                 plot(FLPdata_time(FLPdata_counter,ch),FLPdata_fits{FLPdata_counter,ch}.beta2,'.');
%             end
            
            display(acqTime);
            display(gapTime);
            display('-----------');
        end
        flag=1;
        
        if(acqTime < state.FLP.totalAcqTime) %wait until the data acquisition is done in the current bank only when acqTime < totalAcqTime
            for m=state.spc.acq.modulesInUse
                s=FLIM_test_state(m);
                status=uint16(s);
                while(bitget(status,7)==1) %wait until current bank is no longer armed (making measurement)/until the current bank is full
                    s=FLIM_test_state(m);
                    status=uint16(s);
                end
            end
        end
    end
    for m=state.spc.acq.modulesInUse
        FLIM_StopMeasurement(m);  
    end;
    hold off;
else %continuous aquistion mode without using sequencer
    startTime=clock;
    for m=state.spc.acq.modulesInUse
        FLIM_enable_sequencer(m,0); %turn off sequencer
    end
    for counter=1:state.FLP.numberOfSlices
        if state.timer.abort==1
            display('-------FLP data acquisition aborted');
            break;
        end
        
        timerStart_zFLP; % trigger: this occurs via the start call in timerStart
        
        for m=state.spc.acq.modulesInUse
            s=FLIM_test_state(m);
            status=uint16(s);
            while(bitget(status,7)==1) %wait until SPC is no longer armed (making measurement)
                s=FLIM_test_state(m);
                status=uint16(s);
                %display(status);
            end
        end
        
        acqTime=etime(clock, startTime);
        display(acqTime);
        spc_readPageFLP;
        
        if(counter==1)
            timerProcess_zFLP; %initialize spc construct for fitting purpose
        end
        
        for ch=FLIMchannels
            %spc_fitexp2gaussGY_noplot(ch);
            spc_fitexpgaussGY(ch);
            FLPdata_time(counter,ch)=acqTime;
            FLPdata_lifetimes{counter,ch}=spc.lifetimes{ch};
            FLPdata_fits{counter,ch}=spc.fits{ch};
        end
        
        if timerGetPackageStatus('zFLP')==0 %if aborted stop measurement
            break;
        end
        
        figure(h);
        plot(FLPdata_time(counter,2),FLPdata_fits{counter,2}.beta2,'.');
        
        if(acqTime > state.FLP.totalAcqTime) %if elapsed time > user defined totalAcqTime, stop measurement
            break;
        end
    end
end
zFLP_DoProcessWork; %save the data for all slices into the file and plot the lifetime photon counts of the last slice
if(state.files.autoSave==1)
    state.files.lastAcquisition=state.files.lastAcquisition+1;
end