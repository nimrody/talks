% Input: a{i} = arrival times of packets of stream i
%        l{i} = lengths of packets (in time of transmission assuming they are 
%               the only packets transmitted on the output line).

a{1} = [  0  4  3  4  5  6  7  8  9 10];
l{1} = [  1  1  1  1  1  1  1  1  1  1];

a{2} = [  0 1 2 3 4 5 6];
l{2} = [  1 1 1 1 1 1 1];

a{3} = [  0 1 2 3 ];
l{3} = [  1 1 1 1 ];

N = max(size(a));


% first merge streams - unnecessary

p = ones(1,N);
k = 1;
finished = 0;

while ~finished
	min_t = inf;
	min_t_i = 0;

	for i=1:N
	   if p(i) <= length(a{i})
		   t = a{i}(p(i));
	   	if (t < min_t)
	      	min_t = t;
	         min_t_i = i;
	      end
	   end
	end

	if (min_t_i > 0)
      S{k}.a =  min_t;             					% real arrival time
      S{k}.l =  l{min_t_i}(p(min_t_i));        	% length
		S{k}.i =  min_t_i;
		k = k + 1;
	   p(min_t_i) = p(min_t_i)+1;
	else
	   finished = 1;
	end
end

if 0
	for i = 1:length(S)
	   fprintf('%5.2f %5.2f %d \n', S{i}.a, S{i}.l, S{i}.i);
	end
end


% R(i) - Remaining work to be done for packet of stream i currently
%        in transmission.
R = zeros(1,N);

% X(i) - actual time we started transmitting the packet
X = zeros(1,N);

% p(i) - number of packet at head of queue
% it is either - in transmission   
%              - in queue waiting for a pervious packet of this stream to complete
%                transmission.
%              - has not arrived yet (arrival time in the future)
p = ones(1,N);

% t - current simulation time
t = 0;

% r - number of streams currently running (packets in transmission)
r = 0;

Eps = 10*eps;

finished = 0;
while (~finished)
   
   % Walk over all streams that are not active and find out the next one 
   % to begin transmission
   
   At = inf;
   for i=1:N
  	   if p(i) <= length(a{i})
	      if  (R(i)<=Eps)  & (a{i}(p(i)) < At)
				At = a{i}(p(i));
	         Ti = i;
         end
      end
   end
%%   if (At < t)
%%      At=t;
%%   end
   
	% walk over all *active* streams and calculate their finish time   
   
   E = inf;
   if (r>0)
      for i=1:N
         if (R(i)>Eps) & (R(i)*r < E)
            E = R(i)*r;
            Ei = i;
         end
      end
   end
   Et = E + t;
   
   
   if (E==Inf & At==Inf)
		finished=1;      
   else
	   % determine the next event: arrival of new packet or departure of 
	   % a packet currently in transmission:
   
   	if Et < At
	      % The next event is a departure (a packet will finish transmission).
	      R = R - 1/r*(Et-t);
         
         for k=1:N
            if R(k)<Eps & R(k) > -Eps
		         h = rectangle('Position', [X(k) k (Et-X(k)) 0.75]);
               set(h, 'FaceColor', 'b');
               
               p(k) = p(k) + 1;
               
               % should we start a new packet in this stream (in queue)?
               if p(k) <= length(a{k})
                  if a{k}(p(k)) < Et
                     R(k) = l{k}(p(k));
                     X(k) = Et;
                  else
                     r = r - 1;         % one less stream in transmission
                  end
               else
                  r=r-1;
               end
               
 
            end
         end
         
         t = Et;				 % update Time
      

      
	   else
	      % The next event will be a new arrival on a currently idle stream
	      % Update the work done up to this event (it will slow the server down)
	      if (r>0)
	         R = R - 1/r*(At-t);
	      end
      
	      t = At;        	% update Time
	      X(Ti) = t;	
	      R(Ti) = l{Ti}(p(Ti));
	      r = r + 1;
	   end
   end
end

