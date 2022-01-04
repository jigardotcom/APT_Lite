%         OffsetCalc() : calculates the temporal offset between EEG and Beh Log file
% 
%         Method: 
%         Temporal offest calculated for the session
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
% 
%         Usage
%            >> [TemporalEr del] = OffsetCalc(EegEventSeq, LogEventSeq, EegLatency, LogLatency)
% 
% 
%         Input: 
%         EegEventSeq: the EEG event code sequence
%         LogEventSeq: The Log event code sequence
%         EegLatency: EEG latency sequence
%         LogLatency: Beh Log latency sequence
% 
%         Precondition: 
%         LogEventSequence should not contain updated events (i.e. processed 
%         by ast_process.m)
% 
%         Output:
%             TemporalEr: Temporal offset for this session
%             Del: Transmission delay (Delta) between EXPLOG and EEG events 
%                  estimated for this session
% 
% see also: DPAlign.m
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



        
function [TemporalOffset del] = OffsetCalc(EegEventSeq, LogEventSeq_Old, EegLatency, LogLatency)

% converting four-digit event codes into two-digit
% ast_MakeStructure generates four-digit codes for various
% minigames but at this point EEG contains only two-digit codes
% so this step is necessary
LogEventSeq = mod(LogEventSeq_Old,1000);
l = size(LogEventSeq,1);    % the number of events in the session

n = 0;
m = 0;

% set the number of events taken into aligning process basesd on the total 
% number of events in preent in this session
% (sessions can be as small as 1 event long or as large as 10000 or more events)
% the number of events taken for alignment varies from 1-500 
if(l > 500)
    n = 500;    % the number of events taken into the alignment process
else if (l > 50)
        n = 50;
    else if (l > 20 )
            n = 20;
        else if( l > 5)
                n = 5;
            else
                n = l;
            end
        end
    end
end

%  align the events using Dynamic Programming. The arrays returned, namely,
%  EEGINDEXSEQ and LOGINDEXSEQ contain the locations (indices) where a
%  perfect match has occurred between the event codes in the BehavLog and
%  EEGLog event sequences. The arrays ALIGNED_EEGEVENTSEQ and
%  ALIGNED_LOGEVENTSEQ contain the actual event codes that are in
%  alignment, with a zero value indicating a gap in either of the event
%  sequences.

[EegIndexSeq LogIndexSeq Aligned_EegEventSeq Aligned_LogEventSeq] = DPAlign(EegEventSeq(1:n), LogEventSeq(1:n));

% It is noticed that DP based alignment of event codes yields usually very
% good match in the beginning part of the sequence. Hence we use the first
% 75% of the events in the aligned sequence for temporal offset
% estimation.

m = ceil(size(EegIndexSeq,1)*0.75); % the 75% of aligned events considered for offset estimation

% Estimate the Temporal Offset between the EEG and Log event sequences
for i = 1:m

    TemporalOffesetSeq(i,1) = EegLatency(EegIndexSeq(i)) - LogLatency(LogIndexSeq(i));
end

% Median of array of temporal differences
TemporalOffset = median(TemporalOffesetSeq);

% 
LogLatency_Updated = LogLatency + TemporalOffset;

% Calculate Transmission Delay (Delta) between EXPLOG and EEG
% events. Here we use all the aligned events.
% the estimated offset that has been added to the BehavLog in the earlier
% step is only approximate and as a result sometimes (especially in cases
% where there are rapid succession of events or code replications or
% dropping errors) the EEG Log might lead the Behav Log and cause the
% difference between these two to be negative. Hence an abs() function is
% taken on the difference to avoid the eventuality of events traveling
% backward in time to reach the EEG recorder before they were sent from the
% behavioural computer!!.        

 for i = 1:size(EegIndexSeq,1)
     TransmissionDelay(i,1) = abs(EegLatency(EegIndexSeq(i)) - LogLatency_Updated(LogIndexSeq(i)));
 end
 
% median of array of Transmission Delay (Del) between EXPLOG and EEG
% events
 del = median(TransmissionDelay);
