%function SpcDataAnalysis()
New = SpcDataImport('FLP_20160915(new set up)-ripple',1);
start = find(New(:,1)>2,1,'first');
last = 3680;%length(New(:,1));

%calculate total photon count
photon_count = sum( New(start:length(New(:,2))));

%calculate peak half width
peak = max(New(:,2));
left = start;
while New(left,2)<peak/2
    left = left+1;
end

right = find(New(:,2)==peak,1);
while New(right,2)>peak/2
    right = right+1;
end
half_width = (New(right,1) - New(left,1))*1000;

%calculate ripple
ripple = std(New(start:last,2)) / mean(New(start:last,2));

display(sprintf('photon count: %.3d/ peak half width: %.1f ps',photon_count,half_width));
display(ripple);

%end