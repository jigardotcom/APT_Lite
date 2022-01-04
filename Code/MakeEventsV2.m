%     MakeEvents() - creates a new structure of events based on ExpLog, Temporal Offset and Delta for Temporal offset.
% 
%     Usage:
%         >> events = MakeEvents(ExpLog, TemporalError, T_Delta)
% 
% 
%     Inputs:
%         ExpLog  = the ExpLog structure from which to create events
%         TemporalError: vector of Temporal offset valuess for each session 
%         T_Delta:       vector Average Transmission Delay values estimated
%                        for each session
% 
%     Output:
%       events  = the newly created event structure
%
% Author: Jigar Patel
% University of Hyderabad

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

function [events] = MakeEventsV2(AlignedLatency, AlignedEvent)


% For Each Log Event, create EEG Event with latency calculated using
% the Temporal Offset and Avg. Transmission Delay values estimated for
% each session. 
count = 1;
for i = 1:(size(AlignedLatency))
    
    % Precondition      : i = 1 ; Index value when first session starts 
    %                     stored at SessionIndices(1);   
    % PostCondition     : i = size(SessionIndices,2); where the Index 
    %                     value of last session starts stored
    % Loop Invariant    : Sessions 1...i has been processed and stored
    %                     all the event codes and their respective
    %                     latencies into 'events' structure.

      
        events(i).latency = round(AlignedLatency(i)*512);
        events(i).type = AlignedEvent(i);
        events(i).chanindex = 0;
        events(i).duration = 0;
        events(i).urevent = count;
    
end
end
