
averagetau=zeros(1,1001);
for i=0:1000
    tsim=linspace(0,25,100000);
%     ysim=10000*((0.4+i*0.0002)*exp(-xsim/2.14)+(1-(0.4+i*0.0002))*exp(-xsim/0.69));
    tausim=10000*((0.7+i*0.0002)*exp(-tsim/2.5381)+(1-(0.7+i*0.0002))*exp(-tsim/0.7096));
    averagetau(i+1)=sum(tausim.*tsim)/sum(tausim);
end
% p=0.4:0.0002:0.6;
p=0.7:0.0002:0.9;
figure
plot(p,averagetau)