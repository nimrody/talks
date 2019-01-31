%% GPS & WFQ simulation %%

% Input: a{i} = arrival times of packets of stream i
%        l{i} = lengths of packets (in time of transmission assuming they are 
%               the only packets transmitted on the output line).
%        w(i) = weight assigned to stream i

%%a{1} = [  0  4  5  6  7  8  9 10];
%%l{1} = [  1  1  1  1  1  1  1  1  1];

%%a{2} = [  0 1 2 3 4 5 6];
%%l{2} = [  1 1 1 1 1 1 1];

%%a{3} = [  0 1 2 3 12 ];
%%l{3} = [  1 1 1 1 2];

%%w = [1 1 1];   

a{1} = [ 0 ];
l{1} = [ 100 ];
a{2} = [ 50 ];
l{2} = [ 100 ];
w = [ 1 1];

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

% h(i) - pointer to packet at the head of stream i's queue
%        (note that HOL packet is in service in the GPS server)
h = ones(1,N); 

% t(i) - pointer to packet just after the tail of stream i's queue
tl = ones(1,N);

% F{i}(k) - virtual time of packet k of stream i (packet is in queue)
clear F

% t - current time
t = 0;

% Vt - Virtual time at current real time V(t)
Vt = 0;

% Nextt - real time of packet which will finish service first on GPS
Nextt = inf;

k = 1;          % current event
finished = 0;


while ~finished
   % find the next packet to arrive
   Tarr = inf;
   for k =1:N
      % if there are more packets in this stream...
      if tl(k)<=length(a{k})
         if a{k}(tl(k)) < Tarr
            Tarr = a{k}(tl(k));
            Karr = k;
         end
      end
   end
   
   % find the next packet to depart (in the GPS server)
   finished = 1;
   Fmin = inf;
   for k=1:N
      % if the queue is not empty
      % (i.e., a packet is in transmission in the GPS server)
      if h(k)<=length(a{k})
         finished = 0;
         if h(k) ~= tl(k)  & F{k}(h(k)) < Fmin
            Fmin = F{k}(h(k));
            Kmin = k;
         end
      end
   end
   
   % compute the finish time of this packet
   B = h ~= tl;                          % vector of active sessions
   c = sum(w.*B);
   if (c>Eps)
      Next = t + (Fmin - Vt)*c;          % real time
   else
      Next = inf;
   end
   
   
   
   %% now check what happens next - new arrival or departure:
   if  Tarr < Next
      % a new packet arrived
      %		1. Update virtual time.
      
      c = sum(w.*B);
      if (c>Eps)
         Vt_new = Vt + (Tarr - t) / sum(w .* B);
      else
         Vt_new = Vt;
      end
      
      t_new = Tarr;
      
      figure(3);
      line([t t_new],[ Vt Vt_new]);
      
      Vt = Vt_new;
      t  = t_new;

      % 		2. add it to the queue and stamp it with
      % 			its virtual finish time.
      
      i = tl(Karr);
      if i-1 > 0
         s = max( F{Karr}(i-1), Vt);
      else
         s = Vt;
      end
      
      
      F{Karr}(i) = l{Karr}(i)/w(Karr) + s;
      tl(Karr) = tl(Karr) + 1;
   else
      % a packet has finished service
      
	   B = h ~= tl;                          % vector of active sessions
      Vt_new = Vt + (Next - t) / sum(w .* B);
      t_new = Next;
      
      figure(3);
      line([t t_new],[ Vt Vt_new]);
      
      Vt = Vt_new;
      t  = t_new;
      
      h(Kmin) = h(Kmin) + 1;
   end
end
