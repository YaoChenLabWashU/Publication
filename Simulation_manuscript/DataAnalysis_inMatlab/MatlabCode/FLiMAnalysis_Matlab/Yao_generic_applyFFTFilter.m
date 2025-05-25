function [img] = Yao_generic_applyFFTFilter(img)



for i3 = 1:size(img,3)

%Blur Kernel
ksize = 10;
padsize = ksize; % Larger padsize leads to greater shift
padsize_adjFactor = 1.5;
kernel = zeros(ksize);

%Gaussian Blur
s = 3;
m = ksize/2;
[X, Y] = meshgrid(1:ksize);
kernel = (1/(2*pi*s^2))*exp(-((X-m).^2 + (Y-m).^2)/(2*s^2));

%Pad image
% origimagepad = padimage(img, padsize);
origimagepad = padarray(img(:,:,i3),[padsize padsize]);

%Embed kernel in image that is size of original image + padding
[h, w] = size(img(:,:,3));
[h1, w1] = size(origimagepad);
kernelimagepad = zeros(h1,w1);

kernelimagepad(1:ksize, 1:ksize) = kernel;

%Perform 2D FFTs
fftimagepad = fft2(origimagepad);
fftkernelpad = fft2(kernelimagepad);

fftkernelpad(find(fftkernelpad == 0)) = 1e-6;

%Multiply FFTs
fftblurimagepad = fftimagepad.*fftkernelpad;

%Perform Reverse 2D FFT
blurimagepad = ifft2(fftblurimagepad);

%Remove Padding
padsize_adj = round( padsize*padsize_adjFactor );
blurimageunpad = blurimagepad(padsize_adj+1:padsize_adj+h,padsize_adj+1:padsize_adj+w);





img(:,:,i3) = blurimageunpad;
end



%     function Ipad = padimage(I, p)
%     %This function pads the edges of an image to minimize edge effects
%     %during convolutions and Fourier transforms. %Inputs %I - image to pad %p - size of padding around image %Output %Ipad - padded image
%     
%     %Find size of image
%     [h, w] = size(I);
%     
%     %Pad edges
%     Ipad = zeros(h+2*p, w+2*p);
%     
%     %Middle
%     Ipad(p+1:p+h, p+1:p+w) = I;
%     
%     %Top and Bottom
%     Ipad(1:p, p+1:p+w) = repmat(I(1,1:end), p, 1);
%     Ipad(p+h+1:end, p+1:p+w) = repmat(I(end,1:end), p, 1);
%     
%     %Left and Right
%     Ipad(p+1:p+h, 1:p) = repmat(I(1:end,1), 1, p);
%     Ipad(p+1:p+h, p+w+1:end) = repmat(I(1:end,end), 1, p);
%     
%     %Corners
%     Ipad(1:p, 1:p) = I(1,1); %Top-left
%     Ipad(1:p, p+w+1:end) = I(1,end); %Top-right
%     Ipad(p+h+1:end, 1:p) = I(end,1); %Bottom-left
%     Ipad(p+h+1:end,p+w+1:end) = I(end,end); %Bottom-right
%     end
end