%normalize intensity data

%% normalize with the 95% percentile value from df/f aligned to LED
% datalist=[1 2 3];
% mousenamelist = {'SJ164','SJ165','SJ195','SJ197','SJ198'}; %jRCaMP + dLight cohort
% datalist=[1 2];
% mousenamelist = {'SJ207','SJ208','SJ209','SJ210','SJ168','SJ139','SJ141'}; %bilateral dLight cohort
datalist=[1];
mousenamelist = {'SJ181','SJ182','SJ183','SJ184','SJ185','SJ186','SJ187','SJ188'}; %AKAR + dLight cohort

output_dir='';

for mouse=1:1:length(mousenamelist)
    filename = [output_dir,'analysis_',mousenamelist{mouse}];
    load(filename,'TrialData');

    for d=datalist
        data=zeros(1,length(TrialData(1).dff_LED)*length(TrialData));        
        for i=1:length(TrialData);
            data(length(TrialData(1).dff_LED)*(i-1)+1:length(TrialData(1).dff_LED)*i)=TrialData(i).dff_LED(d,:);
        end
        
        temp=sort(data);
        Normalization_factor(d)=temp(round(length(data)*0.95));
    end
    
    %normalize dff by max amplitude
    for d=datalist
        for i=1:length(TrialData);
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
