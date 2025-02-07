function spc_readPageFLP_sequencer(acq_time)
% read the image/lifetime from the SPC device 
%   and calculate spc.imageMod, spc.project, spc.lifetime
% gy multiboard modified 201202

% GY: read in a full "page".  This code extracted from FLIM_imageAcq
% for simplicity, right now this supports only a single "page" and no
% averaging

global state spc
global FLPdata_time FLPdata_lifetimes FLPdata_counter

% read in a page for each active module and parse it out to the appropriate
% channels (gy multiboard 201202)
for m=state.spc.acq.modulesInUse
    % calculate sizes (gy 201204 dualLaserMode: I think these should be robust)
    blocks_per_frame = state.spc.acq.SPCMemConfig{m+1}.blocks_per_frame;
    frames_per_page = state.spc.acq.SPCMemConfig{m+1}.frames_per_page;  % this should be how multiple channels are stored
    block_length = state.spc.acq.SPCMemConfig{m+1}.block_length;
    maxpage = state.spc.acq.SPCMemConfig{m+1}.maxpage;
    % allocate an array
    image1 = [];
    memorysize =  block_length* blocks_per_frame*  frames_per_page*maxpage;
    image1(memorysize)=0.0;
    % read in page zero (takes ~ 64 ms;  gy 201101)
    [errCode image1]=calllib('spcm32','SPC_read_data_page',m, 0, maxpage-1, image1);
    
    %GY201101  state.spc.internal.image_all = image1;
    % give a warning if page has only zeros
    if sum(image1(:)) == 0
        disp(['*** FLIM WARNING: Data is all zeros [module ' num2str(m+1) ']']);
    end
    spc.errCode  = errCode;
    disp(['total photon count: ',num2str(sum(image1))]);
    
    res = 2^state.spc.acq.SPCdata{m+1}.adc_resolution;
    framesChans = state.spc.acq.modChans{m+1};
    
    for chan=framesChans(:,2);
        for page=1:maxpage
            iEnd=page*res;
            iStart=iEnd-res+1;
            if(page==maxpage)
                spc.lifetimes{chan} =image1(iStart:iEnd); %put the last slice's lifetime into spc.lifetimes{chan} for plotting
            end
            % store all slices into array data global variable
            FLPdata_counter = FLPdata_counter+1;
            FLPdata_time(FLPdata_counter,chan)=acq_time-(maxpage-page)*state.FLP.sliceTime;
            FLPdata_lifetimes{FLPdata_counter,chan}=image1(iStart:iEnd);
        end
    end
    
    
end % over modules