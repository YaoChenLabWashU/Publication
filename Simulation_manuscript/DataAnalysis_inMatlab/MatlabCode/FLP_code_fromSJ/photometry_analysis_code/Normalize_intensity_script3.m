%normalize intensity data

%% normalize with the 95% percentile value from df/f aligned to LED
datalist=[1 2];
mousenamelist = {'SJ139','SJ141','SJ168','SJ207','SJ208','SJ209','SJ210'};
output_dir='';

for mouse=1:1:length(mousenamelist)
    for d=datalist        
        %regular day (training, omission day) data
        mousenamelist = {'SJ139','SJ141','SJ168','SJ207','SJ208','SJ209','SJ210'};
        filename = [output_dir,'analysis_',mousenamelist{mouse}];
        load(filename,'TrialData');
        
        idx=round(TrialData(1).duration*TrialData(1).inputrate/TrialData(1).timebin);
        
        data=[];
        for i=1:length(TrialData)
            if(length(TrialData(i).dff_LED)>=idx)
                data(idx*(i-1)+1:idx*i)=TrialData(i).dff_LED(d,1:idx);
            end
        end
        
        %include day0 (habituation day) data
        if(mouse>=3)
            mousenamelist = {'SJ139-pellet-day0','SJ141-pellet-day0','SJ168-pellet-day0',...
                'SJ207-pellet-day0','SJ208-pellet-day0','SJ209-pellet-day0','SJ210-pellet-day0'};
            filename = [output_dir,'analysis_',mousenamelist{mouse}];
            load(filename,'TrialData');
            
            start=size(data,1);
            for i=1:length(TrialData)
                if(length(TrialData(i).dff_dispense)>=idx)
                    data(start+idx*(i-1)+1:start+idx*i)=TrialData(i).dff_dispense(d,1:idx);
                end
            end
        end
        
        %include post training data
        if(mouse>=4)
            mousenamelist = {'SJ139-pellet-posttraining','SJ141-pellet-posttraining','SJ168-pellet-posttraining',...
                'SJ207-pellet-posttraining','SJ208-pellet-posttraining','SJ209-pellet-posttraining','SJ210-pellet-posttraining'};
            filename = [output_dir,'analysis_',mousenamelist{mouse}];
            load(filename,'TrialData');
            
            start=size(data,1);
            for i=1:length(TrialData)
                if(length(TrialData(i).dff_dispense)>=idx)
                    data(start+idx*(i-1)+1:start+idx*i)=TrialData(i).dff_dispense(d,1:idx);
                end
            end
        end
        
        temp=sort(data);
        Normalization_factor(d)=temp(round(length(data)*0.99));
    end
    
    %Normalize training day data
    mousenamelist = {'SJ139','SJ141','SJ168','SJ207','SJ208','SJ209','SJ210'};
    filename = [output_dir,'analysis_',mousenamelist{mouse}];
    load(filename,'TrialData');
    
    %normalize dff by 99% percentile
    for d=datalist
        for i=1:length(TrialData)
            if(length(TrialData(i).dff_LED)>0)
                TrialData(i).normalized_dff_LED(d,:)=TrialData(i).dff_LED(d,:)/Normalization_factor(d);
            end
            if(length(TrialData(i).dff_zone)>0)
                TrialData(i).normalized_dff_zone(d,:)=TrialData(i).dff_zone(d,:)/Normalization_factor(d);
            end
            if(length(TrialData(i).dff_dispense)>0)
                TrialData(i).normalized_dff_dispense(d,:)=TrialData(i).dff_dispense(d,:)/Normalization_factor(d);
            end
            if(length(TrialData(i).dff_receptacle)>0)
                TrialData(i).normalized_dff_receptacle(d,:)=TrialData(i).dff_receptacle(d,:)/Normalization_factor(d);
            end
        end
    end
    save(filename,'TrialData','-append');
    
    %Normalize day0 data
    if(mouse>=3)
        mousenamelist = {'SJ139-pellet-day0','SJ141-pellet-day0','SJ168-pellet-day0',...
            'SJ207-pellet-day0','SJ208-pellet-day0','SJ209-pellet-day0','SJ210-pellet-day0'};
        filename = [output_dir,'analysis_',mousenamelist{mouse}];
        load(filename,'TrialData');
        
        %normalize dff by 99% percentile
        for d=datalist
            for i=1:length(TrialData)
                if(length(TrialData(i).dff_LED)>0)
                    TrialData(i).normalized_dff_LED(d,:)=TrialData(i).dff_LED(d,:)/Normalization_factor(d);
                end
                if(length(TrialData(i).dff_zone)>0)
                    TrialData(i).normalized_dff_zone(d,:)=TrialData(i).dff_zone(d,:)/Normalization_factor(d);
                end
                if(length(TrialData(i).dff_dispense)>0)
                    TrialData(i).normalized_dff_dispense(d,:)=TrialData(i).dff_dispense(d,:)/Normalization_factor(d);
                end
                if(length(TrialData(i).dff_receptacle)>0)
                    TrialData(i).normalized_dff_receptacle(d,:)=TrialData(i).dff_receptacle(d,:)/Normalization_factor(d);
                end
                if(length(TrialData(i).dff_dispense_max)>0)
                    TrialData(i).normalized_dff_dispense_max(d,:)=TrialData(i).dff_dispense_max(d,:)/Normalization_factor(d);
                end
            end
        end
        save(filename,'TrialData','-append');
    end
    
    %Normalize post training data
    if(mouse>=4)
        mousenamelist = {'SJ139-pellet-posttraining','SJ141-pellet-posttraining','SJ168-pellet-posttraining',...
            'SJ207-pellet-posttraining','SJ208-pellet-posttraining','SJ209-pellet-posttraining','SJ210-pellet-posttraining'};
        filename = [output_dir,'analysis_',mousenamelist{mouse}];
        load(filename,'TrialData');
        
        %normalize dff by 99% percentile
        for d=datalist
            for i=1:length(TrialData)
                if(length(TrialData(i).dff_LED)>0)
                    TrialData(i).normalized_dff_LED(d,:)=TrialData(i).dff_LED(d,:)/Normalization_factor(d);
                end
                if(length(TrialData(i).dff_zone)>0)
                    TrialData(i).normalized_dff_zone(d,:)=TrialData(i).dff_zone(d,:)/Normalization_factor(d);
                end
                if(length(TrialData(i).dff_dispense)>0)
                    TrialData(i).normalized_dff_dispense(d,:)=TrialData(i).dff_dispense(d,:)/Normalization_factor(d);
                end
                if(length(TrialData(i).dff_receptacle)>0)
                    TrialData(i).normalized_dff_receptacle(d,:)=TrialData(i).dff_receptacle(d,:)/Normalization_factor(d);
                end
                if(length(TrialData(i).dff_dispense_max)>0)
                    TrialData(i).normalized_dff_dispense_max(d,:)=TrialData(i).dff_dispense_max(d,:)/Normalization_factor(d);
                end
            end
        end
        save(filename,'TrialData','-append');
    end
    
    
    mouse
    Normalization_factor
end

%% normalize with the max peak
% datalist=[1 2 3];
% mousenamelist = {'SJ195','SJ196','SJ197','SJ198'};
% num_days=11;
% output_dir='';
% for mouse=1:1:length(mousenamelist)
%     filename = [output_dir,'analysis_',mousenamelist{mouse}];
%     load(filename,'TrialData');
%
%     %find max dff
%     M=zeros(4,length(datalist));
%     for d=datalist
%         for i=1:length(TrialData);
%             if(length(TrialData(i).dff_LED)>0)
%                 M(1,d)=max(M(1,d),max(TrialData(i).dff_LED(d,:)));
%             end
%             if(length(TrialData(i).dff_zone)>0)
%                 M(2,d)=max(M(2,d),max(TrialData(i).dff_zone(d,:)));
%             end
%             if(length(TrialData(i).dff_dispense)>0)
%                 M(3,d)=max(M(3,d),max(TrialData(i).dff_dispense(d,:)));
%             end
%             if(length(TrialData(i).dff_receptacle)>0)
%                 M(4,d)=max(M(4,d),max(TrialData(i).dff_receptacle(d,:)));
%             end
%         end
%     end
%
%     %normalize dff by max amplitude
%     for d=datalist
%         for i=1:length(TrialData);
%             if(length(TrialData(i).dff_LED)>0)
%                 TrialData(i).normalized_dff_LED(d,:)=TrialData(i).dff_LED(d,:)/M(1,d);
%             end
%             if(length(TrialData(i).dff_zone)>0)
%                 TrialData(i).normalized_dff_zone(d,:)=TrialData(i).dff_zone(d,:)/M(2,d);
%             end
%             if(length(TrialData(i).dff_dispense)>0)
%                 TrialData(i).normalized_dff_dispense(d,:)=TrialData(i).dff_dispense(d,:)/M(3,d);
%             end
%             if(length(TrialData(i).dff_receptacle)>0)
%                 TrialData(i).normalized_dff_receptacle(d,:)=TrialData(i).dff_receptacle(d,:)/M(4,d);
%             end
%         end
%     end
%
%     save(filename,'TrialData','-append');
% end
