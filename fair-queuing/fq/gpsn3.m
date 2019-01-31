dt = 0.01;

T   = 10;
Nt  = T/dt;			% number of time slots
Ns  = 2;				% number of sessions

% nt(n) - node type: 1 - multiplexer(scheduler), 2 - demultiplexer
nt_sched = 1;
nt_demux = 2;
nt(1) = nt_sched;
nt(2) = nt_sched;
nt(3) = nt_sched;
nt(4) = nt_demux;
nt(5) = nt_sched;
nt(6) = nt_sched;

Nn  = length(nt);	% number of nodes in network



% a(n,j,tk) - arrival function for node n, session j at time tk
%             (amount of information supplied as input in the time dt*[tk-1, tk])

a = zeros(Nn, Ns, Nt);
a(1,1,1:round(Nt/2)) = 1 * dt * ones(1,round(Nt/2));
a(2,2,1:round(Nt/3)) = 1 * dt * ones(1,round(Nt/3));

% r(n,j) - session j arrives at node n from node r(n,j)

r(1, :) = [ 0  0];
r(2, :) = [ 0  0];
r(3, :) = [ 1  2];
r(4, :) = [ 3  3];
r(5, :) = [ 4  0];
r(6, :) = [ 0  4];


% w(n,j) - weight of session j at node n
w(1, :) = [ 1 1 ];
w(2, :) = [ 1 1 ];
w(3, :) = [ 1 1 ];
w(4, :) = [ 1 1 ];   %% doesn't really matter as it is not a scheduler
w(5, :) = [ 1 1 ];
w(6, :) = [ 1 1 ];

% R(n) - rate of scheduler n output line (amount of work done in dt time)
% is not used for demux elements (as they have infinite output line speed).
R = ones(Nn) * dt;

% s(n,j,tk) - work function for node n, session j at time tk
%             (amount of work done in time dt*[tk-1, tk])

s = zeros(Nn, Ns, Nt);

% q(n, j, tk) - backlog for node n, session j at time tk
q = zeros(Nn, Ns, Nt);
	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  a(1,1,:)                                    a(5,1,:)
%   ,----.                                           ,----.
%   |  1 |---.                               ,------>|  5 |->
%   `----'    \          s(3,1,:)   demux   /        `----'
%              \  ,----.           ,----.  /    
%               >-|  3 |---------->|  4 |-+
%  a(2,2,:)    /  `----'           `----'  \   a(6,2,:)
%   ,----.    /          s(3,2,:)           \        ,----.
%   |  2 |---'                               `------>|  6 |->
%   `----'                                           `----'
%
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for tk = 1:(Nt-1)
   if mod(tk,1/dt) == 0
      fprintf('%10d  %5.4f\n', tk, tk*dt);
   end
   
   for n = 1:Nn
      if nt(n) == nt_sched
         % a scheduler multiplexes several streams fairly
         % into *one* output line.
         
         ACT = zeros(1,Ns);
         DEMAND = zeros(1,Ns);
         
         for i=1:Ns
            if r(n,i)>0
               tt = s(r(n,i), i, tk);
            else
               tt = 0;
            end
            DEMAND(i) = q(n,i,tk) + a(n,i,tk) +  tt;
         end
         
         % now determine the amount of work done for each session
         % excess goes into queue
         
         alloc = fair(R(n), DEMAND, w(n,:));
         
         for i = 1:Ns
            if alloc(i)>0
               s(n, i, tk+1) = alloc(i);
                         
               if r(n,i)>0
                  qq = s(r(n,i),i,tk);
               else
                  qq = 0;
               end
               
               qq = qq + a(n, i, tk);
               
               q(n, i, tk+1) = q(n, i, tk) + qq - alloc(i);
            end
         end
               
      elseif nt(n) == nt_demux
         
         % A demux, de-multiplex several streams to several other nodes.
         % No scheduling is done as we assume the output lines of the demux
         % have infinite capacity. If this is not the case, place a
         % scheduler on these lines (after the demux).
         
         % find our output lines
         [dest_node, session] = find(r == n);
         for i=1:length(dest_node)
            %% FIXME - we hack the next node's input as an arrival
            %% function
            
            a(dest_node(i), session(i), tk+1) = ...
                a(dest_node(i), session(i), tk+1) + ...
                a(n, session(i), tk) + s(r(n,session(i)), session(i), tk);
         end
         
      else
         error('unknown node type');
      end
      
   end
end
