% SessionIndex() - Get the Indices of each session in EXPLOG
% 
%     Usage:
%         >>SessionIndices = SessionIndex(ExpLog)
%         
%     Input:
%         EXPLOG: EXPLOG structure generated by ast_makestructure
%         
%     Output:
%         SessionIndices (integer arrray) : contains indices of onset times
%         for each session in EXPLOG
%         
%     Precondition : EXPLOG is generated with ast_makestructure.m and NOT 
%                    already processed by ast_process.m
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

    

function Session = SessionIndex(ExpLog)

%SessionIndices = [];
i = 1;
Session_Count = 1;
% Determine start of first session
while(ExpLog(i).time == 0) % look for non zero value in latency column which will indicate start of new session.
    i = i+1;
end
Session(Session_Count).start = i;
while(i <= size(ExpLog,2))
    % new session is identified by looking at when the timestamp of EXPLOG 
    % event has zero value. This loop looks at ExpLog structure
    % record-by-record.
    
    % Precondition      : i = 1 ; The beginning of the Logfile
    % PostCondition     : i = size(ExpLog,2); The end of the Logfile
    % Loop Invariant    : the Records from 1..i has been processed in the
    %                     ExpLog structure 
    
    if(ExpLog(i).time == 0)     
        
        % it has been observed that at the onset of a new session 
        % there are 4 zeros recorded in the Latency column of the BehavLog
        % file corresponding to the header text message announcing the
        % ensuing session. Since we already processed one zero and the
        % onset value occurs in the fourth subsequent row, 4 records are
        % being skipped to obtain the  next session onset index
        
        Session(Session_Count).end = (i-1); % end of previous session.
        while(ExpLog(i).time == 0) % look for non zero value in latency column which will indicate start of new session.
            i = i+1;
        end
        %i = i+4;
        Session_Count =  Session_Count +1; %increment session count by 1;
        Session(Session_Count).start = i;        
    else
        i = i+1;
    end
end
Session(Session_Count).end = size(ExpLog,2); % final session ends at end of file.
%SessionIndices = [SessionIndices; (size(ExpLog,2)+4)];
end