dt = 0.01;

T   = 10;
Nt  = T/dt;			% number of time slots
Ns  = 4;				% number of sessions

% nt(n) - node type: 1 - multiplexer(scheduler), 2 - demultiplexer
nt_sched = 1;
nt_demux = 2;
nt(1) = nt_demux;
nt(2) = nt_sched;
nt(3) = nt_demux;
nt(4) = nt_sched;
nt(5) = nt_demux;
nt(6) = nt_sched;
nt(7) = nt_demux;
nt(8) = nt_sched;
nt(9) = nt_sched;
nt(10)= nt_sched;
nt(11)= nt_sched;
nt(12)= nt_sched;

Nn  = length(nt);	% number of nodes in network


% a(n,j,tk) - arrival function for node n, session j at time tk
%             (amount of information supplied as input in the time dt*[tk-1, tk])

a = zeros(Nn, Ns, Nt);
a(2,1,:) = 1 * dt * ones(1,Nt);
a(4,2,:) = 1 * dt * ones(1,Nt);
a(6,3,:) = 1 * dt * ones(1,Nt);
a(8,4,:) = 1 * dt * ones(1,Nt);


% r(n,j) - session j arrives at node n from node r(n,j)

r(1, :) = [ 0  4  4  4];
r(2, :) = [ 1  0  1  1];
r(3, :) = [ 2  2  0  2];
r(4, :) = [ 3  3  3  0];
r(5, :) = [ 3  3  3  0];
r(6, :) = [ 3  3  3  0];
r(7, :) = [ 3  3  3  0];
r(8, :) = [ 3  3  3  0];
r(9, :) = [ 3  3  3  0];
r(10,:) = [ 3  3  3  0];
r(11,:) = [ 3  3  3  0];
r(12,:) = [ 3  3  3  0];


% w(n,j) - weight of session j at node n
w(1, :) = [ 1 1 1 1];
w(2, :) = [ 1 1 1 1];
w(3, :) = [ 1 1 1 1];
w(4, :) = [ 1 1 1 1];
w(5, :) = [ 1 1 1 1];
w(6, :) = [ 1 1 1 1];
w(7, :) = [ 1 1 1 1];
w(8, :) = [ 1 1 1 1];
w(9, :) = [ 1 1 1 1];
w(10,:) = [ 1 1 1 1];
w(11,:) = [ 1 1 1 1];




rs = size(r);
rw = size(w);

if (rs(1) ~= Nn) | (rs(2) ~= Ns)
   error('r() - size mismatch');
elseif (rw(1) ~= Nn) | (rw(2) ~= Ns)
   error('w() - size mismatch');
end

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
%                      ,---. 
%                      | 9 | s(9,2,:)
%                      `---'
%                        ^        ,- a(1,1,:)
%                        |        |
%                        |        V
%                      .---.    ,---. 
%            ,---------| 1 |--->| 2 +-----------.      
%            |         `---'    `---'           |    
% a(8,4,:) ,---.       demux                  ,-+-.    ,---.
%      --->| 8 |                        demux | 3 |--->| 10|
%          `---'                              `---'    `---'
%            ^                                  |       s(10,3,:)
%            |                                  V   
% ,---.    ,-+-.                              .---.
% | 12|<---| 7 |demux                         | 4 |<--- a(4,2,:)
% `---'    `---'                              `-+-'
% s(12,1,:)  ^                                  |
%            |                 demux            |   
%            |         ,---.   ,---.            |        
%            `---------| 6 |<--| 5 |<-----------'
%                      `---'   `---'  
%                        ^       |
%                        |       |   
%             a(6,3,:) --'       V
%                              ,---.
%                              | 11|  s(11,4,:)
%                              `---'
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
