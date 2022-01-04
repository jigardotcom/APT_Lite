%     SessionAlign(): A function that aligns the EEG and Behavioural Log
%                     file events based on event code and their latency
%                     values using a nearest neighbour heuristic.  
% 
%     Method: 
% 
%         1.	Fetch events one by one along with latencies from Behavioural Log
%               sequences (LogE and LogL) 
%         2.	Take the latency of the current Behavioural event and
%               subtract this value from the entire array of EEG latencies 
%         3.	Determine the nearest event by finding minimum of the
%               resulting array in step 2.  
%         4.	Compare the event codes belonging to the latency values
%         5.	If events are matched, it’s a matched event, copy event and
%               its latency from EEG into new array and store its index
%               into one variable which keeps track of last EEG event that
%               has matched.    
%         6.	If not, then consider event as dropped and copy the event and
%               its latency value from the Behavioural Log into the new
%               EEG event array and increment a variable that keeps track
%               of dropped or missing events (called 'bad' in the code here!)   
% 
% 
%     Usage:
%             >> [NewEEGL NewEEGV mark logindex bad Log_SuccDelta Log_EEG_Delta] = SessionAlign(EEGE, LogE, EEGL, LogL)
% 
%     Input: 
%         EEGE: EEG Event Sequence
%         LogE: Behav Log file Event Sequence
%         EEGL: EEG Latencies
%         LogL: Behav Log file Latencies
% 
%     Precondition: the latencies of Log file must have been updated using
%                    Temporal Offset and Transmission delay (Delta) values
%                    estimated for the particular session.   
% 
%     Output: 
%         NewEEGL : New Array containing Latencies
%         NewEEGV : New array containing Event codes
%         mark    : index value of EEG where the last match had occurred 
%                   (useful to determine the indices corresponding to the
%                   boundary of the EEG session). 
%         logindex : array containing indices of dropped Events (for
%                           debugging and future use) 
%         bad      : total number of dropped events (for debugging)
%         Log_SuccDelta : Successive difference of Log latencies (for use
%                           in statistical analysis) 
%         Log_EEG_Delta : The difference between EEG and Log latencies
%                         (aligned) (for use in statistical analysis)
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


function [NewEEGL NewEEGV mark logindex bad Log_SuccDelta Log_EEG_Delta] = SessionAlign(EEGE, LogE, EEGL, LogL)

% initilization 
count = 1;      % keeps track of the number of elements in the new array
bad = 0;    
mark = 0;
mark2 = 1;      % keeping track of number of elements in logindex array 
I = 0;          % index of the nearest neighbour found
logindex = [];  % indices of dropped events stored here
Log_SuccDelta = [];
Log_EEG_Delta= [];

for i = 1:size(LogE,1) 
    
    % Precondition      : i = 1 ; The beginning of the Logfile Session 
    % PostCondition     : entire Logfile Session have been processed and
    %                     aligned with the events in respective EEG
    %                     session.
    % Loop Invariant    : events form 1..i are processed from event sequence
    %                     LogE

    
    if (mark < size(EEGL,1)) 
        
        if(LogE(i) ~= 0 )
            LogLatency = LogL(i);
            Temp = LogLatency - EEGL((mark+1):size(EEGL,1),1); % Subtract the latency of the event from array of EEG latencies
            [ M(i,1) I] = min(abs(Temp)); % get minimum to identify the temporal nearest neighbour 
            EEGEvent = EEGE(I+mark);
            LogEvent = mod(LogE(i),1000);
            if( EEGEvent == LogEvent) % Compare event codes and if they match then ...
%                 NewEEGL(count,1) = EEGL(I+mark);
%                 NewEEGV(count,1) = EEGE(I+mark);
                NewEEGL(count,1) = LogL(i);
                NewEEGV(count,1) = LogE(i);
                NewLogL(count,1) = LogL(i);
                NewLogE(count,1) = LogE(i);
                count = count+1;
                mark = mark + I ;
            else                    % if event codes do not match then ...
                NewEEGL(count,1) = LogL(i);
                NewEEGV(count,1) = LogE(i);
                NewLogL(count,1) = LogL(i);
                NewLogE(count,1) = LogE(i);
                logindex(mark2,1) = i;
                mark2 = mark2 +1;
                count = count+1;
                bad = bad + 1;
            end
        end
        
    end
    
end

j = 1;

% Statistical Analysis: This code was used to plot the graph between
% LogSuccDelta (the difference between successive BehavLog aligned events)
% and LogEEGDelta (the difference between aligned EEG and BehavLog
% latencies). We observed that when the events occurred very rapidly,
% the transmission delays were also high

for i  = 2:size(NewEEGL)
    
    Log_SuccDelta(j,1) = NewLogL(i) - NewLogL(i-1);
    Log_EEG_Delta(j,1) = (abs(NewEEGL(i) - NewLogL(i)))*1000;
    j = j + 1;
end
    