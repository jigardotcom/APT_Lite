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

function [events] = MakeEventsV3(ExpLog, TemporalError, T_Delta)

% Convert Explog ticks into seconds and store them in array
for i = 1:size(ExpLog,2)
    Logticks(i,1) = (ExpLog(i).mark)/2826280000;
    LogEventSeq(i,1) = ExpLog(i).code;
    
end
% Computes Session onset Indices
SessionIndices = SessionIndex(ExpLog);

% For Each Log Event, create EEG Event with latency calculated using
% the Temporal Offset and Avg. Transmission Delay values estimated for
% each session. 
count = 1;
for i = 1:(size(SessionIndices,2))
    
    % Precondition      : i = 1 ; Index value when first session starts 
    %                     stored at SessionIndices(1);   
    % PostCondition     : i = size(SessionIndices,2); where the Index 
    %                     value of last session starts stored
    % Loop Invariant    : Sessions 1...i has been processed and stored
    %                     all the event codes and their respective
    %                     latencies into 'events' structure.

    
    if( i >size(TemporalError,2)) break; end
    
    Session_count = 1;
    
    Logticks_Session_Unsorted = Logticks(SessionIndices(i).start:SessionIndices(i).end,1);
    LogEventSeq_Session_Unsorted = LogEventSeq(SessionIndices(i).start:SessionIndices(i).end,1);
    
    [Logticks_Session LogEventSeq_Session] = SortBehLog(LogEventSeq_Session_Unsorted, Logticks_Session_Unsorted);
 
    
    while (Session_count < size(Logticks_Session,1))
        
        
        events(count).latency = round((Logticks_Session(Session_count,1) + TemporalError(i) - T_Delta(i))*512);
        events(count).type = ExpLog(count).code;
        events(count).chanindex = 0;
        events(count).duration = 0;
        events(count).urevent = count;
        
        
        count = count + 1;
        Session_count = Session_count + 1;
    end
    
end
end
