
lifetimes_norm_all=[];

for i=1:FLPdata_counter
    lifetimes_norm=squeeze(FLPdata_lifetimes(i,1,:))/max(squeeze(FLPdata_lifetimes(i,1,:)));
    lifetimes_norm_all=[lifetimes_norm_all lifetimes_norm];
    For_plot=mean(transpose(lifetimes_norm_all));
    save('histogram','lifetimes_norm_all','For_plot')
end