%plot by day group (beginner, intermediate, trained)

clear all;
%mousenamelist = {'SJ181','SJ182','SJ183','SJ184'}; %A2A Cre
%mousenamelist = {'SJ185','SJ186','SJ187','SJ188'}; %D1 Cre

%mousenamelist = {'SJ181','SJ182','SJ183','SJ184','SJ185','SJ186','SJ187','SJ188'};
%mousenamelist = {'SJ213','SJ214','SJ215','SJ216','SJ217','SJ218','SJ219','SJ220'};

mousenamelist = {'SJ181','SJ182','SJ183','SJ184','SJ185','SJ186','SJ187','SJ188',...
    'SJ213','SJ214','SJ215','SJ216','SJ217','SJ218','SJ219','SJ220'};

var_name='dff';
figure_var_name='dff(%)';

duration=100; %analysis duration in sec/ trial
baseline_duration=20; %baseline_duration in sec: duration of the baseline used for the df/f calculation in
%group_criteria=[0.3, 0.7]; %success rate criteria cutoff for intermediate and trained group 0.3,0.7


%% intensity across many mice: comparing reward omission trials, normalization by max for mouse average, SEM across mouse average
filename = ['analysis_',mousenamelist{1},'.mat'];
load(filename,'TrialData','successrate');
plot_num=10;

% find max mouse averages for normalization factor
for mouse=1:length(mousenamelist)
    display(mousenamelist{mouse});
    filename = ['analysis_',mousenamelist{mouse},'.mat'];
    load(filename,'TrialData');
    
    for d=1:length(TrialData(1).ch_name)
        norm_factor(mouse,d)=0;
        
        temp=[];
        for i=1:length(TrialData)
            x=eval(['TrialData(i).',var_name,'_LED']);
            if(length(x)>0)
                if(x(d,1)~=0)
                    temp=[temp,x(d,:)];
                end
            end
        end
        temp=sort(temp);
        
        if(length(temp)>0)
            norm_factor(mouse,d)=temp(round(length(temp)*0.99));
        end
        
        display(['normalization factor: ',num2str(norm_factor(mouse,d))]);
    end
end

%%
%normalize all trial dff values
for mouse=1:length(mousenamelist)
    display(mousenamelist{mouse});
    filename = ['analysis_',mousenamelist{mouse},'.mat'];
    load(filename,'TrialData');
    
    for d=1:length(TrialData(1).ch_name)
        for i=1:length(TrialData)
            if(length(TrialData(i).dff_trigger)>0)
                TrialData(i).norm_dff_trigger(d,:)=TrialData(i).dff_trigger(d,:)/norm_factor(mouse,d);
            end
            if(length(TrialData(i).dff_LED)>0)
                TrialData(i).norm_dff_LED(d,:)=TrialData(i).dff_LED(d,:)/norm_factor(mouse,d);
            end
            if(length(TrialData(i).dff_zone)>0)
                TrialData(i).norm_dff_zone(d,:)=TrialData(i).dff_zone(d,:)/norm_factor(mouse,d);
            end
            if(length(TrialData(i).dff_dispense)>0)
                TrialData(i).norm_dff_dispense(d,:)=TrialData(i).dff_dispense(d,:)/norm_factor(mouse,d);
            end
            if(length(TrialData(i).dff_receptacle)>0)
                TrialData(i).norm_dff_receptacle(d,:)=TrialData(i).dff_receptacle(d,:)/norm_factor(mouse,d);
            end
            if(length(TrialData(i).dff_receptacle2)>0)
                TrialData(i).norm_dff_receptacle2(d,:)=TrialData(i).dff_receptacle2(d,:)/norm_factor(mouse,d);
            end
        end        
    end
    
    save(filename,'TrialData','-append');
end