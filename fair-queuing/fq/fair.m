function r = fair(x, d, w)
% fair(x, d, w)
%
%    Allocate resource x fairly to several requests
%    x - amount of resource to allocate
%    d - demands of all users
%    w - relative weights


N = length(w);
if N ~= length(d)
   error('vector lengths do not match');
end

maxd = max(d);

r = zeros(1,N);       
unsatisfied = logical(r==0 & d>0);


while any(unsatisfied)
   R = x / sum(w(unsatisfied) );
   y = R * w;
   
   
   if  all(d(unsatisfied) <= y(unsatisfied))
      r(unsatisfied) = d(unsatisfied);
      return;
   end
   
   if all( d(unsatisfied) >= y(unsatisfied))
      r(unsatisfied) = y(unsatisfied);
      return;
   end
   
   [dmin, imin] = min(d.*(unsatisfied) + maxd*(~unsatisfied));
   r(imin) = d(imin);
   x = x - d(imin);
   
   unsatisfied = logical(r==0 & d>0);
end

