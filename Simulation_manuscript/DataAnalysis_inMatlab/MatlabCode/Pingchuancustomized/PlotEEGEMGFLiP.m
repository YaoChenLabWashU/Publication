function out=PlotEEGEMGFLiP(rawdat_dir, mouse, fileprefix, filepostfix, acqn, frequency, constant, FigureVisible)

% Written by Yao, 4/5/2021
% I ran it under 2021a. Does not work with 2014 or 2012.
% clear the workspace first.
% frequency is the EEG/EMG input frequency, typically 400.

% Define the rawdat_dir, fileprefix and frequency first.

% Pingchuan: removed the ScoringData in input, ScoringData is automatically paired with
% the acqn number. Added another input constant. In most of the cases of
% 24-hour recording, the first-hour recording doesn't start with the first
% acqn. 'constant' correct the number between the recording from which hour
% and which acqn number.
EEGfile=['extracted_data/downsampEEG_Acq',num2str(acqn),'.npy']
EEGdata=readNPY(EEGfile);
Fs = 200; % 
tWindow = 10; % The window must be long enough to get 64ms of the signal
NWindow = Fs*tWindow; % Number of elements the window must have
window = hamming(NWindow); % Window used in the spectrogram
NFFT = NWindow;
NOverlap = NWindow*0.99; % We want a 99% overlap, 

% save ScoringData
% Get your ScoringData this way
% data=readNPY('StatesAcq2_hr0_mod.npy'); data2=readNPY('StatesAcq2_hr1_mod.npy');
% ScoringData=[data', data2'];
scoring_python=['extracted_data/StatesAcq',num2str(acqn),'_hr0.npy']
ScoringData=readNPY(scoring_python);
ScoringData=ScoringData'; % Pingchuan changed, based on the way we name the npy sleep scoring file. 11.19.2021.

% Create figure
figure1 = figure('Visible',FigureVisible);
figure1.Position=[10 10 800 1300];

% load EEG/EMG data, scale them correctly and convert the scale to
% microsecond, and store in ScaledEEGEMG.
ScaledEEGEMG=cell(3,1);
channels = [0 2 3]; %if EEG/EMG channels are 0, 2 and 3
for i=1:3
    file=sprintf(strcat(rawdat_dir,'/AD%d_%d.mat'),channels(i),acqn)
    load(file);
    eval(['ScaledEEGEMG{', int2str(i), ',1}=AD', int2str(channels(i)), '_', int2str(acqn), '.data/5000*10^6;']); %What is a more elegant way to access the data?
end

% load FLiP data
% FLiPfile=sprintf('%s_acqn%d_Analysis.mat',fileprefix,acqn);
FLiPfile=[fileprefix,'_analysis_',num2str(acqn-constant),'h_',filepostfix,'.mat'] % Pingchuan changed, based on the way I name the FLiP analysis files.
load(FLiPfile);
TimeRange=max(time); %time range to plot, in seconds, based on FLiP data. We need to specify it because ephys data sometimes exceeded the duration of FliP data.

% Create subplot
subplot7 = subplot(7,1,1,'Parent',figure1);
hold(subplot7,'on');
spectrogram(EEGdata, window, NOverlap, NFFT, Fs,'yaxis');
ylim([1,15])
caxis([-40 -10])
colorbar('off')
box(subplot7,'on');
hold(subplot7,'off');


subplot1 = subplot(7,1,2,'Parent',figure1);
hold(subplot1,'on');

plot(ScaledEEGEMG{1,1},'Parent',subplot1);
xlim(subplot1,[0 length(ScaledEEGEMG{1,1})]);

% Create ylabel
ylabel('EEG1 (uV)');

box(subplot1,'on');
hold(subplot1,'off');
% Create subplot
subplot2 = subplot(7,1,3,'Parent',figure1);
hold(subplot2,'on');

% Create plot
plot(ScaledEEGEMG{2,1},'Parent',subplot2);
xlim(subplot2,[0 length(ScaledEEGEMG{2,1})]);


% Create ylabel
ylabel('EEG2 (uV)');

box(subplot2,'on');
hold(subplot2,'off');
% Create subplot
subplot3 = subplot(7,1,4,'Parent',figure1);
hold(subplot3,'on');

% Create plot
EEGtime=1/400:1/400:3600;
plot(EEGtime, ScaledEEGEMG{3,1},'Parent',subplot3);
xlim(subplot3,[0 3600]);
% ylim(subplot3,[0 800])

% Create ylabel
ylabel('EMG (uV)');
xlabel('Time (sec)')

box(subplot3,'on');
hold(subplot3,'off');
% Create subplot
subplot(7,1,5,'Parent',figure1);

% Create heatmap
ScoringData=ScoringData([1:TimeRange/4]);
ScoringHeatMap=heatmap(figure1,ScoringData,'Colormap',[0 1 0;0 0 1;1 0 0;.5 0 .5],...
    'GridVisible','off',...
    'FontColor',[0 0 0],...
    'ColorLimits',[1 4],...
    'Title','Scoring (green=wake;blue=NREM;red=REM;yellow=QuietWake)');
ScoringHeatMap.YDisplayLabels=repmat(' ', 1, 1);
ScoringHeatMap.XDisplayLabels=repmat(' ', length(ScoringData), 1);
    
    
    
% Scoring=heatmap(figure1,ScoringData,'Colormap',[0 1 0;0 0 1;1 0 0],...
% 'GridVisible','off',...
% 'FontColor',[0 0 0],...
% 'ColorLimits',[1 3]);
% Scoring.XDisplayLabels=repmat(' ', 452, 1);
% Scoring.YDisplayLabels=repmat(' ', 1, 1);
% Scoring.Title='Scoring (green=wake;blue=NREM;red=REM)'

% Create subplot
subplot4 = subplot(7,1,6,'Parent',figure1);
hold(subplot4,'on');

% Create plot
plot(time,tau_empTrunc,'Parent', subplot4); % Pingchuan changed from tau to tau_empTrunc, based my FLiP analysis output, I can choose which tau to plot.
% scatter(time(1973:3430),tau(1973:3430), 10, 'filled','b');
xlim(subplot4,[0 max(time)]);

% Create ylabel
ylabel('lifetime (ns)');

% Create xlabel
xlabel(' ');

% Create title
title({'Fluorescence lifetime'});

% Uncomment the following line to preserve the Y-limits of the axes
% ylim(subplot4,[1.77 1.81]);
box(subplot4,'on');
hold(subplot4,'off');
% Create subplot
subplot5 = subplot(7,1,7,'Parent',figure1);
hold(subplot5,'on');

% Create plot
plot(time,photoncount,'Parent', subplot5);
xlim(subplot5,[0 max(time)]);

% Create xlabel
xlabel('Time (sec)');

% Create title
title('Photon counts');


% Uncomment the following line to preserve the Y-limits of the axes
% ylim(subplot5,[190000 240000]);
box(subplot5,'on');
hold(subplot5,'off');
% Create textbox
OverallTitle=[mouse, num2str(acqn)];
annotation(figure1,'textbox',...
    [0.282608695652174 0.94695127409373 0.386287614404159 0.0299003316648511],...
    'String',OverallTitle,...
    'LineStyle','none',...
    'FontWeight','bold');
% Insert title for the whole figure;

%save everything
figurefile=sprintf('%s_acqn%d', fileprefix, acqn);
figurepngfile=[fileprefix,'_acqn_',num2str(acqn),'.png'];
% savefig(figure1, figurefile);
saveas(figure1,figurepngfile);

Summaryfile=sprintf('%s_acqn%d_summary', fileprefix, acqn);
% save(Summaryfile, 'ScaledEEGEMG', 'ScoringData', 'ScoringHeatMap');
