%DPrime() is a function to calculate the D' estimate
%
%Usage : D = DPrime(Hits, Misses, False_Alarms, Correct_Rejections)

function [D] = DPrime(Hits, Misses, FA, CR) % FA = False Alarms, CR = Correct Rejections

if(Hits ==0)
    Hits = 1;
end
if(Misses ==0)
    Misses = 1;
end
if(FA ==0)
    FA = 1;
end
if(CR ==0)
    CR = 1;
end

HitRate = Hits / (Hits + Misses);
FARate = FA / (FA + CR);
D = icdf('Normal',HitRate,0,1)-icdf('Normal',FARate,0,1);
end