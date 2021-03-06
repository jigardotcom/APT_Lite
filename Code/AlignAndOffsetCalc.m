% AlignAndOffsetCalc() - Estimate temporal offset between EEG.event
%                        timestamps and Behavioural EXPLOG events by
%                        aligning these two structures

%   Temporal offsets are estimated session-by-session between EEG.event and
%   EXPLOG event latencies.
%   The reason the offset is calculated for each session separately, and not
%   once just at the beginning, is because of the unspecified (potentially unequal)
%   amount of time spent between successive sessions.

% Method :
%     1.	convert the ticks from EXPLOG and EEG latencies into seconds
%     2.	Determine the session indices
%     3.	For each session calculate the temporal offset and the average
%           transmission delay (delta) in the following way:
%         a.	Take the first few events (depends on the total number of
%               events in the session) and use Dynamic Programming method to
%               align them by matching event codes between EEG and EXPLOG
%         b.	Using aligned sequences, calculate the latency difference
%               between latencies of first few aligned events (depending on
%               the total number of aligned events)
%         c.	Calculate the median of the all the latency differences
%               (median is used to reduce the effect of the outliers)
%         d.	Add the estimated median value to the EXPLOG lantencies and
%               then calculate the difference between all the aligned events
%               to estimate the transmission delay (delta) between EXPLOG
%               and EEG.event
%         e.	Calculate the median of delta values.
%     4.	Return the offsets and delta values for each session

%     Usage
%             >> [AlignedLatency AlignedEvent TemporalError T_Delta mark Log_SuccDelta Log_EEG_Delta] = AlignAndOffsetCalc(ExpLog, Event)
%
%
%     Input:
%         Explog = The ExpLog Structure constructed from behavioural log using ast_makestructure.m
%         Event  = Event structure from EEG dataset file
%
%     Precondition: ExpLogStructure is a structure of the form generated by
%                   MakeStructure
%     Precondition: ExpLog structure is not already processed by ast_process.m
%
%     Output:
%         AlignedLatency :
%             (cell array) : the Latency values of the aligned events of
%             each session (for future use)
%         AlignedEvent :
%             (cell array) : the Event codes of each session (for future
%             use)
%         TemporalError :
%             (double array): The Temporal offset for each session
%         T_Delta :
%             (double array): The Delta for Temporal Offset for each session
%         mark :
%             (integer array): EEG index where each session ends (for
%             future use)
%         Log_SuccDelta :
%             (cell array): the first difference between log latencies for
%             each session (for future use)
%         Log_EEG_Delta:
%             (cell array): the difference between EEG and updated log
%             latencies (for future use)
%
% see also: SessionIndex.m, SortBehLog.m, OffsetCalc.m, SessionAlign.m
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



function [AlignedLatency AlignedEvent TemporalError T_Delta mark Log_SuccDelta Log_EEG_Delta] = AlignAndOffsetCalc(ExpLog,UpdatedExpLog, Event)

% Initialize return values
[fname, fpath] = uiputfile('/.txt','Save Alignment log as');

if (fname)
    filepath = strcat(fpath,fname);
    
    Res = fopen(filepath,'w');     % Creats the Result file
    fprintf(Res,'Alignment Stats\n');

    
    AlignedLatency = [];
    AlignedEvent=[];
    count = 1;
    % filtering EEG events (hardware generated events are digarded) as well as
    % converting EEG latencies into seconds and storing them into arrays for
    % easy use
    for i = 1:size(Event,2)
        if(Event(i).type < 254)
            EEGEventSeq(count,1) = str2num(Event(i).type);
            EegLatency(count,1) = Event(i).latency/512;
            count = count+1;
        end
    end
    
    % converting logticks into seconds and storing event sequences and their
    % latencies into arrays for easy use
    for i = 1:size(ExpLog,2)
        Logticks(i,1) = (ExpLog(i).mark)/2826280000;
        LogEventSeq(i,1) = ExpLog(i).code;
        LogEventSeq_Updated(i,1) = UpdatedExpLog(i).code;
    end
    
    % computing the indecies of each game sessions
    
    SessionIndices = SessionIndex(ExpLog);
    
    
    % initialize mark , will be storing the index of last eeg event in every
    % session : used to stip off eeg from events that are already aligned as
    % it is not known where in EEG session is starting and ending, a
    % prograssive alignment is needed.
    
    mark = [];
    el = size(EegLatency,1);
    
    for i = 1:size(SessionIndices,2)
        
        % Precondition      : P:- i = 1 ; Index value when first session starts
        %                     stored at SessionIndices(1);
        % PostCondition     : R:- i = size(SessionIndices,2); where the Index
        %                     value of last session starts stored
        % Loop Invariant    : sessions 1...i has been processed and calculated
        %                     Temporal Offset and Transmission delay for each
        %                     session
        
        if (sum(mark) < size(EEGEventSeq,1)) % stop if ran out of eeg events
            
            %pulling up chuncks of EEG events and latency sequences
            EegEvent_Session{i} = EEGEventSeq(sum(mark)+1:el);
            EegLatency_Session{i} = EegLatency(sum(mark)+1:el);
            
            % getting subset of log event and latency sequence for the session
            
            Logticks_Session{i} = Logticks(SessionIndices(i).start:SessionIndices(i).end,1);
            LogEventSeq_Session{i} = LogEventSeq(SessionIndices(i).start:SessionIndices(i).end,1);
            LogEventSeq_Updated_Session = LogEventSeq_Updated(SessionIndices(i).start:SessionIndices(i).end,1);
            
            % sort the Beh log file
            [Logticks_Sorted{i} LogEventSeq_Sorted{i} Index{i}] = SortBehLog(LogEventSeq_Session{i}, Logticks_Session{i});
            
            %Calculate the offset for the session
            [TemporalError(i) T_Delta(i)] = OffsetCalc(EegEvent_Session{i}, LogEventSeq_Sorted{i}, EegLatency_Session{i}, Logticks_Sorted{i});
            
            %add offset and substract the delta from log latency sequence
            Logticks_Offsetted{i} = Logticks_Sorted{i} + TemporalError(i)- T_Delta(i);
            
            %Align log and eeg event and latency sequence based on both latancy
            %and event code
            [NewEegLatency_Session{i} NewEegEvent_Session{i} mark(i) logindex{i} bad(i) Log_SuccDelta{i} Log_EEG_Delta{i}] = SessionAlign(EegEvent_Session{i}, LogEventSeq_Sorted{i}, EegLatency_Session{i}, Logticks_Offsetted{i});
            
            % Merge the aligned event and latency sequences with the previous
            % session
            AlignedLatency = [AlignedLatency;NewEegLatency_Session{i} ];
            AlignedEvent = [AlignedEvent;LogEventSeq_Updated_Session(Index{i}) ];
            
            
            % Printing stats in log file
            
            fprintf(Res,'\n\n\nSession No:,');                    
            fwrite(Res,num2str(i));
            fprintf(Res,'\nNo of Events in Session:,');                    
            fwrite(Res,num2str(mark(i)));
            fprintf(Res,'\nTemporal Offset for this session(Seconds):,');                    
            fwrite(Res,num2str(TemporalError(i)));
            fprintf(Res,'\nTransmission Delay for this session(Seconds):,');                    
            fwrite(Res,num2str(T_Delta(i)));
            fprintf(Res,'\nNo of Dropped/Misplaced Events:,');                    
            fwrite(Res,num2str(bad(i)));
            
            
            
        end
        fprintf(strcat('\nProcessed Session No : ',num2str(i),' So far, ',num2str(sum(mark)),' Events has been Processed'));
        
    end
end
fclose(Res); 
end
