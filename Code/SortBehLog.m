%         SortBehLog() : Sorts the Behavioural Log based on ticks
% 
%         Usage:
% 
%         >> [NewLogLatency NewLogEvents Index] = SortBehLog(LogEvents, LogLatency)
% 
%         Input:
% 
%         LogEvents : Log Events Sequence array
%         LogLatency: Log Latency Sequence array
%       
%          Output:
%          NewLogLatency : Sorted Log Events Sequence array
%          NewLogEvents  : Sorted Log Latency Sequence array
%          Index         : Original Index values from the unsorted array 
% 
% Author: Jigar Patel
% 2011 University of Hyderabad
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.


function [NewLogLatency NewLogEvents Index] = SortBehLog(LogEvents, LogLatency)

L = size(LogLatency);
[Temp Index] = sort(LogLatency);

for i=1:L
    NewLogLatency(i,1) = LogLatency(Index(i),1);
    NewLogEvents(i,1) = LogEvents(Index(i),1);
end
end

    