global windowSize; %moving average window_size in ms
global timebin; %timebin ms

%windowsize_list=[20 40 100 200 300 400 500];
%timebin_list=[20 40 50];

windowsize_list=[400];
timebin_list=[20];

for i=1:length(timebin_list)
    display('------');
    display(timebin_list(i));
    for j=1:length(windowsize_list)
        if(windowsize_list(j)<=timebin_list(i))
            continue;
        end
        
        display(windowsize_list(j));
        
        timebin=timebin_list(i);
        windowSize=windowsize_list(j);
        
        analysisByTrial_simplePellet;
        %plot_simplepellet_Intensity;
        
        analysisByTrial2;
        
        Normalize_intensity_script2_simplePellet;
    end
end

