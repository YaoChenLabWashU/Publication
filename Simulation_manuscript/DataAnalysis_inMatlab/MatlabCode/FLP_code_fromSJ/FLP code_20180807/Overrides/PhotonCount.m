function PhotonCount=PhotonCount
global spc
nChan=numel(spc.lifetimes);
for k=1:nChan; 
    gy(1,k)= sum(spc.lifetimes{k});
end; 
PhotonCount=gy;
disp(gy);

end

