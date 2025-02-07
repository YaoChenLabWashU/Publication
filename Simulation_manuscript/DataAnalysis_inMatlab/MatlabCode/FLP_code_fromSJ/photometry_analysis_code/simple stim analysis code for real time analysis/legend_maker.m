function legend_label = legend_maker(legend_mark, legend_type)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

legend_label={};
counter=0;

if strcmp(legend_type,'day')==1
    for i=1:length(legend_mark)
        if legend_mark(i)==1
            counter=counter+1;
            legend_label{counter}=['day',num2str(i)];
            
            if(i==12 || i==13)
                legend_label{counter}='25% reward omission day';
            end
            if i==14
                legend_label{counter}='LED omission day';
            end
        end
    end
elseif strcmp(legend_type,'group_day')==1
    for i=1:3
        if(legend_mark(i)==1)
            counter=counter+1;
            
            if(i==1)
                legend_label{counter}=['beginner'];
            elseif (i==2)
                legend_label{counter}=['intermediate'];
            else 
                legend_label{counter}=['trained'];
            end
        end
    end
elseif strcmp(legend_type,'group_day+1')==1 %including LED omission day
    for i=1:4
        if(legend_mark(i)==1)
            counter=counter+1;
            
            if(i==1)
                legend_label{counter}=['beginner'];
            elseif (i==2)
                legend_label{counter}=['intermediate'];
            elseif (i==3) 
                legend_label{counter}=['trained'];
            else
                legend_label{counter}=['LED omission session'];
            end
        end
    end
elseif strcmp(legend_type,'group_day+2')==1 %including reward omission trials
    for i=1:4
        if(legend_mark(i)==1)
            counter=counter+1;
            
            if(i==1)
                legend_label{counter}=['beginner'];
            elseif (i==2)
                legend_label{counter}=['intermediate'];
            elseif (i==3) 
                legend_label{counter}=['trained'];
            else
                legend_label{counter}=['reward omission trials'];
            end
        end
    end
elseif strcmp(legend_type,'trial')==1 %including reward omission trials
    for i=1:length(legend_mark)
        legend_label{i}=['trial',num2str(i)];
    end   
end