


% Find sample files
mainFolder =...
    'I:\For Paul(Yao_images)';

subFolder = 'nucleus';



fileList = dir(sprintf('%s\\%s',mainFolder,subFolder));
fileList = fileList(3:end);



% Load sample files into image stack
for iFile = 1:size(fileList,1)
% for iFile = 1
    load( sprintf('%s\\%s\\%s',...
        mainFolder,...
        subFolder,...
        fileList(iFile).name ) ,'-mat' )
    
    
    
    img = temp;
    
    
    
    if iFile == 1
        % Initialize image stack
        imgStack = zeros( size(img,1),size(img,2),...
            size(img,3),...
            size(fileList,1) );
    end
    imgStack(:,:,:,iFile) = img;
    
    
    
% % %     figure; imshow( img )
% % %     impixelinfo
    
end
clear img temp
clear mainFolder subFolder fileList




%% Test on sample image
% #4

for iImg = 11;

thres_blue = 0.75;
thres_GB = 0.25;
thres_red = 0.1;
discard_range = 1;


thres_centroid_size = 10;
thres_centroid_dist = 15;


img = imgStack(:,:,:,iImg);
img_orig = img;


% img = medfilt2(img,[2 2]);



% Want to remove some of the edge
%   Convert to grayscale
imgBW = im2bw(img,0.1);
%   Fill in holes
imgBW = imfill(imgBW,'holes');
%   Erode edge
se = strel('disk',5);
imgBW = imerode(imgBW,se);


% Make changes to regular image
I = imgBW(:,:);
for i1 = 1:size(img,1)
    for iColor = 1:size(img,3);
        img(i1,:,iColor) = img(i1,:,iColor).*imgBW(i1,:);
    end
end


% Other operations
I = img(:,:,3) > thres_blue &...
    img(:,:,1) < thres_GB & img(:,:,2) < thres_GB;

for i1 = 1:size(img,1)
    for i2 = 1:size(img,2)
        if I(i1,i2) == 1
            
            r1 = max([1 i1-discard_range]):...
                min([size(img,1) i1+discard_range]);
            r2 = max([1 i2-discard_range]):...
                min([size(img,2) i2+discard_range]);
            
            
            img(r1,r2,:) =...
                zeros( size(r1,2) , size(r2,2) ,size(img,3) );
            
        end
    end
end


I2 = img(:,:,1) < thres_red;

for i1 = 1:size(img,1)
    for i2 = 1:size(img,2)
        if any(img(i1,i2,:) > 0)
        if I2(i1,i2) == 1
            
            r1 = max([1 i1-discard_range]):...
                min([size(img,1) i1+discard_range]);
            r2 = max([1 i2-discard_range]):...
                min([size(img,2) i2+discard_range]);
            
            
            img(r1,r2,:) =...
                zeros( size(r1,2) , size(r2,2) ,size(img,3) );
            
        end
        end
    end
end



% Remove blocks with less than 5 pixels
%   Record block information such as pixel coordinates and centroid
minBlockSize = 5;

imgBW = im2bw(img,0.1);

cc = regionprops(imgBW,'PixelIdxList','PixelList','Centroid');
imgProp = cell(1,3);

img_temp = zeros( size(img,1),size(img,2), 1 );
for i = 1:size( cc ,1)
    if size( cc(i).PixelIdxList ,1) >= minBlockSize
        img_temp( cc(i).PixelIdxList ) = 1;
        
        if isempty(imgProp{1,1})
            imgProp{1,1} = cc(i).PixelList;
            imgProp{1,2} = cc(i).Centroid;
            imgProp{1,3} = size( cc(i).PixelList ,1);
        else
            imgProp{end+1,1} = cc(i).PixelList;
            imgProp{end,2} = cc(i).Centroid;
            imgProp{end,3} = size( cc(i).PixelList ,1);
        end
        
    end
end

for i1 = 1:size(img,1)
    for i2 = 1:size(img,2)
        if img_temp(i1,i2) == 0
            img(i1,i2,:) = 0;
        end
    end
end


figure; imshow(img); impixelinfo



if size(imgProp,1) > 2
% Remove blocks whose centroid is too far from other blocks
%   If block has more than X pixels, do not remove
idx_remove = zeros( size(imgProp,1) ,1);
for i = 1:size(imgProp,1)
    if imgProp{i,3} < thres_centroid_size
        
        c = imgProp{i,2};
        
        
        idx_remove(i) = 1;
        for j = 1:size(imgProp,1)
            if j ~= i
                
                if any( hypot(...
                        imgProp{j,1}(:,1) - c(1) ,...
                        imgProp{j,1}(:,2) - c(2) ) < thres_centroid_dist )
                    idx_remove(i) = 0;
                    break
                end
                
            end
        end
        
        
    end
end


if any(idx_remove)
    temp = 1:size(idx_remove,1);
    idx_remove = temp(idx_remove==1);
    imgProp(idx_remove,:) = [];
end


img_temp = zeros( size(img,1),size(img,2), size(img,3) );
for i = 1:size(imgProp,1)
    pixelList = imgProp{i,1};
    for j = 1:size(pixelList,1)
        img_temp( pixelList(j,2) , pixelList(j,1) ,:) =...
            img( pixelList(j,2) , pixelList(j,1) ,:);
    end
end
img = img_temp;




end



% Fit ellipse
%   Move all coordinates into one matrix
pixelList = [];
for i = 1:size(imgProp,1)
    if i == 1
        pixelList = imgProp{i,1};
    else
        pixelList = cat(1,pixelList,imgProp{i,1});
    end
end

imgBW = zeros( size(img,1),size(img,2) ,1);
for i = 1:size(pixelList,1)
    imgBW( pixelList(i,2),pixelList(i,1) ) = 1;
end



% % % figure; imshow(imgBW)





XY = pixelList;
%-----------------------------------------------------------
% From Nikolai Chernov's Ellipse Fit (Direct method)

centroid = mean(XY);   % the centroid of the data set

D1 = [(XY(:,1)-centroid(1)).^2, (XY(:,1)-centroid(1)).*(XY(:,2)-centroid(2)),...
      (XY(:,2)-centroid(2)).^2];
D2 = [XY(:,1)-centroid(1), XY(:,2)-centroid(2), ones(size(XY,1),1)];
S1 = D1'*D1;
S2 = D1'*D2;
S3 = D2'*D2;
T = -inv(S3)*S2';
M = S1 + S2*T;
M = [M(3,:)./2; -M(2,:); M(1,:)./2];
[eigVec,eigVal] = eig(M);
cond = 4*eigVec(1,:).*eigVec(3,:)-eigVec(2,:).^2;
A1 = eigVec(:,find(cond>0));
A = [A1; T*A1];
A4 = A(4)-2*A(1)*centroid(1)-A(2)*centroid(2);
A5 = A(5)-2*A(3)*centroid(2)-A(2)*centroid(1);
A6 = A(6)+A(1)*centroid(1)^2+A(3)*centroid(2)^2+...
     A(2)*centroid(1)*centroid(2)-A(4)*centroid(1)-A(5)*centroid(2);
A(4) = A4;  A(5) = A5;  A(6) = A6;
A = A/norm(A);

%-----------------------------------------------------------


a = num2str(A(1)); 
b = num2str(A(2));
c = num2str(A(3)); 
d = num2str(A(4)); 
f = num2str(A(5)); 
g = num2str(A(6));


figure; imshow(img_orig)
hold on

eqt= ['(',a, ')*x^2 + (',b,')*x*y + (',c,')*y^2 + (',d,')*x+ (',f,')*y + (',g,')']; 
xmin=1*min(XY(:,1)); 
xmax=1*max(XY(:,2)); 
h_fit = ezplot(eqt,[xmin,xmax]);
set(h_fit,'Color','w')
% scatter(XY(:,1),XY(:,2)) 

hold off



%%
% % http://mathworld.wolfram.com/Ellipse.html
% %   Equations 15, 19-23
% a = A(1);
% b = A(2)/2;
% c = A(3);
% d = A(4)/2;
% f = A(5)/2;
% g = A(6);
% 
% 
% 
% denom1 = (b^2-a*c);
% c_x = (c*d-b*f) / denom1;
% c_y = (a*f-b*d) / denom1;
% 
% 
% 
% num1 = 2*( a*f^2 + c*d^2 + g*b^2 - 2*b*d*f - a*c*g );
% denom_a = denom1*(sqrt( (a-c)^2 -4*b^2) - (a+c));
% denom_b = denom1*(-sqrt( (a-c)^2 -4*b^2) - (a+c));
% a_prime = sqrt( num1/denom_a );
% b_prime = sqrt( num1/denom_b );
% 
% % delta = b^2-a*c;
% % 
% % x0 = (c*d - b*f)/delta;
% % y0 = (a*f - b*d)/delta;
% % 
% % nom = 2 * (a*f^2 + c*d^2 + g*b^2 - 2*b*d*f - a*c*g);
% % s = sqrt(1 + (4*b^2)/(a-c)^2);
% % 
% % a_prime = sqrt(nom/(delta* ( (c-a)*s -(c+a))));
% % 
% % b_prime = sqrt(nom/(delta* ( (a-c)*s -(c+a))));
% 
% 
% 
% majoraxes = max([a_prime b_prime]);
% minoraxes = min([a_prime b_prime]);
% 
% 
% 
% if b == 0
%     if a < c
%         phi = 0;
%     else
%         phi = pi()/2;
%     end
% else
%     phi = 1/2*acot( (a-c)/(2*b) );
%     
%     if a < c
%     else
%         phi = phi + pi()/2;
%     end
% end
% phi = -phi;
% 
% % % % phi = 0.5 * acot((c-a)/(2*b)); 
% % % % if (a_prime < b_prime)
% % % %     phi = pi/2 - phi;
% % % % end
% 
% 
% 
% t = linspace(0,2*pi(),100);
% X = c_x + majoraxes *cos(t)*cos(phi) - minoraxes *sin(t)*sin(phi);
% Y = c_y + majoraxes *cos(t)*sin(phi) + minoraxes *sin(t)*cos(phi);
% 
% % X = real(X);
% % Y = real(Y);
% 
% 
% 
% figure; imshow(img_orig)
% hold on
% plot(X,Y,'w.')
% hold off









end


%---------------------------------------------------------------

