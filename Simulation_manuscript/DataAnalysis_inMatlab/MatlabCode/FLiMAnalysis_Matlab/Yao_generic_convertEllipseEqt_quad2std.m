function [x0,y0,semimajor,semiminor,phi] = Yao_generic_convertEllipseEqt_quad2std(A)
% phi (angle of orientation) is not accurate
%   Use getOrientation

a = A(1);
b = A(2)/2;
c = A(3);
d = A(4)/2;
f = A(5)/2;
g = A(6);

delta = b^2-a*c;

x0 = (c*d - b*f)/delta;
y0 = (a*f - b*d)/delta;



nom = 2 * (a*f^2 + c*d^2 + g*b^2 - 2*b*d*f - a*c*g);
s = sqrt(1 + (4*b^2)/(a-c)^2);

a_prime = sqrt(nom/(delta* ( (c-a)*s -(c+a))));

b_prime = sqrt(nom/(delta* ( (a-c)*s -(c+a))));

semimajor = max(a_prime, b_prime);
semiminor = min(a_prime, b_prime);

clear nom s a_prime b_prime



% This formula has been proven to not work well
%     if b == 0
%         if a < c
%             phi = 0;
%         else
%             phi = pi()/2;
%         end
%     else
%         if a < c
%             phi = 1/2 * acot((a-c)/(2*b));
%         else
%             phi = pi()/2+ 1/2 * acot((a-c)/(2*b));
%         end
%     end
phi = 1/2 * acot((a-c)/(2*b));


end