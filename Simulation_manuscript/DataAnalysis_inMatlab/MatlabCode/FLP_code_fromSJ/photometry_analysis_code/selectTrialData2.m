function [output] = selectTrialData2(TrialData,var_name,d,trial_types,idx_list)
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here
output=[];
counter=0;

for i=idx_list
    flag=0;
    for j=1:length(trial_types)
        if(TrialData(i).trialtype == trial_types(j))
            flag=1;
        end
    end
    
    if(flag==1)
        x=eval(['TrialData(i).',var_name]);
        if(strcmp(var_name,'intensity_baseline')==1)
            if(x(d)~=0)
                counter=counter+1;
                output(counter,1:length(x))=x(d);
            end
        elseif(length(x)>1) %if data (TrialData(i).varname(d,:)) exists
            if(x(d,1)~=0)
                counter=counter+1;
                output(counter,1:length(x))=x(d,:);
            end
            
            %             if(d==0) %lifetime data
            %                 if(x(1)~=0)
            %                     counter=counter+1;
            %                     output(counter,1:length(x))=x;
            %                 end
            %             else %intensity data
            %                 if(x(d,1)~=0)
            %                     counter=counter+1;
            %                     output(counter,1:length(x))=x(d,:);
            %                 end
            %             end
        end
        
        %         display(['day ',num2str(TrialData(i).day)]);
        %         display(['trial ',num2str(TrialData(i).trialnumber)]);
        %         display(['reward time : ',num2str(TrialData(i).rewardtime)]);
        %         display(['entering_time2 : ',num2str(TrialData(i).entering_time2)]);
    end
end