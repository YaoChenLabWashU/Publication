%plot by each day for all mice

clear all;
num_days=11;
plot_num=3;

mousenamelist = {'SJ200','SJ201','SJ202',...
    'SJ164','SJ165','SJ195','SJ197','SJ198',...
    'SJ207','SJ208','SJ209','SJ210','SJ139','SJ141','SJ168',...
    'SJ185','SJ186','SJ187','SJ188',...
    'SJ184',...
    'SJ130','SJ136','SJ137','SJ138',...
    'SJ91','SJ110',...
    'SJ149','SJ150','SJ151',...
    'SJ191_AKAR','SJ192_AKAR','SJ193_AKAR','SJ194_AKAR'};

%mousenamelist = {'SJ199','SJ163','SJ196','SJ169'};
cmap=hsv(length(mousenamelist));

for i=1:plot_num
    for j=1:num_days
        outputdata(i,j).size=0;
        outputdata(1,j).data=[];
    end
end

for mouse=1:length(mousenamelist)
    filename = ['analysis_',mousenamelist{mouse},'.mat'];
    load(filename,'successrate','latency_combined','occupancy_combined','latency2_combined');
    
    if(length(successrate)>=num_days)
        idx=num_days;
    else
        idx=length(successrate)-1;
    end
    occupancy_combined(find(occupancy_combined>=3))=3;
    
    figure(1);
    plot([1:1:idx],successrate(1:idx),'color',cmap(mouse,:));
    title('success rate vs. day');
    ylabel('success rate (fraction)');
    xlabel('day');
    hold on;
    for i=1:idx
        outputdata(1,i).size=outputdata(1,i).size+1;
        outputdata(1,i).data(outputdata(1,i).size)=successrate(i);
    end
    
    m_latency=[];   ste_latency=[];
    for i=1:idx   
        temp=latency_combined(i,find(latency_combined(i,:)>0));
        m_latency(i)=mean(temp);
        ste_latency(i)=std(temp)/sqrt(length(temp));
        
        outputdata(2,i).data(outputdata(2,i).size+1:outputdata(2,i).size+length(temp))=temp;
        outputdata(2,i).size=outputdata(2,i).size+length(temp);
    end
    figure(2);
    errorbar(1:idx,m_latency,ste_latency,'Color', cmap(mouse,:));
    title('latency to enter LED zone vs. day');
    ylabel('latency to enter LED zone(s)');
    xlabel('day');
    hold on;

    m_occupancy=[];   ste_occupancy=[];
    for i=1:idx
        temp=occupancy_combined(i,find(occupancy_combined(i,:)>0));
        m_occupancy(i)=mean(temp);
        ste_occupancy(i)=std(temp)/sqrt(length(temp));
        
        outputdata(3,i).data(outputdata(3,i).size+1:outputdata(3,i).size+length(temp))=temp;
        outputdata(3,i).size=outputdata(3,i).size+length(temp);
    end
    figure(3);
    errorbar(1:idx,m_occupancy,ste_occupancy,'color',cmap(mouse,:));
    title('occupancy vs. day');
    ylabel('occupancy (s)');
    xlabel('day');
    hold on;
end

%autoArrangeFigures();
delete(findall(0,'Type','figure'));

for i=1:plot_num
    for j=1:num_days
        m(j)=mean(outputdata(i,j).data);
        ste(j)=std(outputdata(i,j).data);
    end
    
    figure(i);
    confplot(1:num_days,m,ste,ste,'color',[1 0 0],'LineWidth',2);
    hold on;
end

figure(1);
title('success rate vs. day');
ylabel('success rate (fraction)');
xlabel('day');

figure(2);
title('latency to enter LED zone vs. day');
ylabel('latency to enter LED zone(s)');
xlabel('day');
hold on;

figure(3);
title('occupancy vs. day');
ylabel('occupancy (s)');
xlabel('day');
hold on;
%autoArrangeFigures();
return;
