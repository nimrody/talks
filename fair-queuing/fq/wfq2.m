%% GPS & WFQ simulation %%

% Input: a{i} = arrival times of packets of stream i
%        l{i} = lengths of packets (in time of transmission assuming they are 
%               the only packets transmitted on the output line).
%        w(i) = weight assigned to stream i

a{1} = [  0  4  5  6  7  8  9 10];
l{1} = [  1  1  1  1  1  1  1  1  1];

a{2} = [  0 1 2 3 4 5 6];
l{2} = [  1 1 1 1 1 1 1];

a{3} = [  0 1 2 3 12 ];
l{3} = [  1 1 1 1 2];

w = [1 1 1];   

N = max(size(a));

color = {'blue', 'red', 'green', 'cyan', 'magenta'};

%% GPS Simulation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

En = zeros(1,N);

% R(i) - Remaining work to be done for packet of stream i currently
%        in transmission.
R = zeros(1,N);


% S(i) - Total work done on session i
S = zeros(1,N);

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
   
	% walk over all *active* streams and calculate their finish time   
   
   E = inf;
   for i=1:N
      if (R(i)>Eps) & (R(i)/rate(i,w,R) < E)
         E = R(i)/rate(i,w,R);
         Ei = i;
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
         Ro = R;
         
         for k=1:N
            if Ro(k) > Eps
               c = rate(k,w,Ro)*(Et-t);
               R(k) = R(k) - c;
               
               % draw S(k) - amount of work done on stream k
               figure(2);
               subplot(N,1,N-k+1);
	            h=line([t Et], [S(k) S(k)+c]);
	            set(h, 'Color', color{k});
                  
               S(k) = S(k) + c;
               
               if R(k)<Eps & R(k) > -Eps
                  
                  En(k) = Et;
                  % draw the packets transmitted on the link
                  figure(1);
			         h = rectangle('Position', [X(k) k (Et-X(k)) 0.75]);
         	      set(h, 'FaceColor', color{k});
                  
                  % draw line from packet arrival to departure
                  figure(2);
                  h = line([a{k}(p(k))  Et], [S(k) S(k)]);
                  set(h, 'LineStyle', ':');
                  
                  % record the delay experienced by this packet
                  Delay{k}(p(k)) = Et - a{k}(p(k));	
                  
            	   p(k) = p(k) + 1;
               
	               % should we start a new packet in this stream (in queue)?
   	            if p(k) <= length(a{k})
      	            if a{k}(p(k)) < Et
         	            R(k) = l{k}(p(k));
            	         X(k) = Et;
	                  end
                  end
                  
               end
            end
         end
         
         t = Et;				 % update Time
 	   else
	      % The next event will be a new arrival on a currently idle stream
	      % Update the work done up to this event (it will slow the server down)
         for k=1:N
            if R(k)>Eps 
               c = rate(k,w,R)*(At-t);
               R(k) = R(k) - c;
               
               % draw S(k) - amount of work done on stream k
               figure(2);
               subplot(N,1,N-k+1);
	            h=line([t At], [S(k) S(k)+c]);
	            set(h, 'Color', color{k});
                     
               S(k) = S(k) + c;
            end
         end
         
         % draw S(k) - amount of work done on stream k
         figure(2);
         subplot(N,1,N-Ti+1);
         h=line([En(Ti) At], [S(Ti) S(Ti)]);
         set(h, 'Color', color{Ti});        
         
         
         t = At;        	% update Time
	      X(Ti) = t;	
	      R(Ti) = l{Ti}(p(Ti));
	   end
   end
end

figure(2);
for k=1:N
   subplot(N,1,N-k+1);
   axis([0 t 0 max(S)]);
   s = sprintf('Stream %d', k);
   title(s);
end
figure(1);
axis([0 t 1 N+1]);


%% WFQ Simulation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% first merge streams - unnecessary

clear E
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
      E{k}.a =  min_t;             					% real arrival time
      E{k}.l =  l{min_t_i}(p(min_t_i));        	% length
		E{k}.i =  min_t_i;
		k = k + 1;
	   p(min_t_i) = p(min_t_i)+1;
	else
	   finished = 1;
	end
end


if 0
   % print out the list of upcoming packets
	for i = 1:length(S)
	   fprintf('%5.2f %5.2f %d \n', E{i}.a, E{i}.l, E{i}.i);
	end
end

% F(i) - virtual time of last packet packet transmitted on stream i
F = zeros(1,N);

% t - current time
t = 0;

% Vt - Virtual time at current real time V(t)
Vt = 0;

k = 1;          % current event
finished = 0; 

while ~finished
   % a new packet is received
   p = E(k);
   s = max(F(p.i), Vt);
   
   
   
   
   finished = 1;
end
