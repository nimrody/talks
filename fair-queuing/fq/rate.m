function r=rate(i,w,R)

Eps=10*eps;

active = R > Eps;

r = w(i)/sum(w.*active);