% DPAlign() - This MATLAB function is used to align a part of behavioral log 
%             event series with EEG log event series
%
% Usage 
%   >> [EegIndexSeq LogIndexSeq EegEventSeq LogEventSeq] = DPAlign(a,b)
%
% Input:
%
%   a : EEG event series (after removal of event codes greater than 254)
%   b : behavioral Log event series (after removal of 'IGNORE' events and sorting)
%
% Output: 
% 
%   EegIndexSeq :   event indices in the EEG log file where a perfect match
%                   was found with Log event code.
%   LogIndexSeq :   event indices in the behavioral log file where a
%                   perfect match was found with EEG event code. 
%   EegEventSeq :   aligned event sequences for the EEG. 0 indicates gap in
%                                                       alignment
%   LogEventSeq :   aligned Behavioral log event sequences. 0 indicates gap
%                                                       in alignment
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


function [EegIndexSeq LogIndexSeq EegEventSeq LogEventSeq] = DPAlign(a,b)

% This is a global sequence alignment using Needleman/Wunsch technique.
% The first step in the global alignment dynamic programming approach 
% is to create a matrix with M (size of a) + 1 columns and N (size of b) + 1 
% rows where M and N correspond to the size of the sequences to be aligned.
% This is the DPMatrix.
% TraceBackMatrix is DPMatrix with cells assigned with direction markers 
% as explained below.
% The first row and first column of DPMatrix can be initially filled with 0.
% EegLength and LogLength are lengths of a and b vectors, respectively.

EegLenth = size(a,1) + 1;                 % determining the size of the matrix
LogLenth = size(b,1) + 1;
DPMatrix = zeros(LogLenth,EegLenth);                   % Initializing the Matrix
TraceBackMatrix = zeros(LogLenth,EegLenth);

% An advanced scoring scheme is assumed where
% score(i,j)= 2 if the residue at position i of sequence #1 is the same 
% as the residue at position j of sequence #2 (match score); otherwise
% score(i,j) = -1 (mismatch score)
% gap penalty=-2
%
GapPenalty = -2;                             % Gap Penalty

EegIndexSeq = [];
LogIndexSeq  = [];
EegEventSeq  = [];
LogEventSeq = [];


% Matrix fill step:
%
% The matrix fill step finds the maximum global alignment score by starting
% in the upper left hand corner in the matrix and finding the maximal score
% Mi,j for each position in the matrix. In order to find  
% DPMatrix(i,j) for any i,j it is minimal to know the score for the matrix
% positions to the left, above and diagonal to i, j. In terms of matrix
% positions, it is necessary to know   
% DPMatrix(i-1,j), DPMatrix(i,j-1) and DPMatrix(i-1,j-1).
%
% For each position, Mi,j is defined to be the maximum score at position i,j; i.e.
%
% DPMatrix(i,j) = MAXIMUM[
%     DPMatrix(i-1, j-1) + score(i,j) (match/mismatch in the diagonal),
%     DPMatrix(i,j-1) + gap penalty (gap in sequence #1),
%     DPMatrix(i-1,j) + gap penalty (gap in sequence #2)]
% After a value has been assigned to a cell the direction is placed back
% into the cell that resulted in the maximum score ('D' for diagonal, 'L'
% for left and 'U' for upper).  


TraceBackMatrix(1,1) =  'D';

for i = 2:LogLenth
    TraceBackMatrix(1,i) = 'L';
end

for j = 2:EegLenth
    TraceBackMatrix(j,1) = 'U';
end


for i = 2:LogLenth           % Forward Loop of the Dynamic Programming Sequence Alignment
    for j = 2:EegLenth
        if(b(i-1) == a(j-1))
            Match = 2;
        else 
            Match = -1;
        end
        Match = Match + DPMatrix(i-1,j-1);
        GapSeq1 = DPMatrix(i,j-1) + GapPenalty;
        GapSeq2 = DPMatrix(i-1,j) + GapPenalty;
        [DPMatrix(i,j) I]  = max([Match GapSeq1 GapSeq2]);
        switch I                % Storing directions in Direction/Traceback Matrix
            case 1
                TraceBackMatrix(i,j) = 'D';
            case 2
                TraceBackMatrix(i,j) = 'L';
            case 3
                TraceBackMatrix(i,j) = 'U';
        end
                
    end
end

% Traceback Step:
%
% After the matrix fill step, the maximum global alignment score for the
% two sequences is 3. The traceback step will determine the actual
% alignment(s) that result in the maximum score.  
% The traceback step begins in the EegLength,LogLength position in the
% matrix, i.e. the position where both sequences are globally aligned. 
% Since we have kept pointers back to all possible predecessors, the
% traceback step is simple. At each cell, we look to see where we move next
% according to the pointers.  
%
% Once the traceback is completed we get a path leading to maximal global
% alignment. 
% The sequence we thus obtain are in reverse and have to be inverted to get
% the correct sequence. 


count = 1;
count2 = 1;
RowIndex = LogLenth;
ColumnIndex = EegLenth;
while (RowIndex >= 1 && ColumnIndex > 1)          % TRACEBACK Loop of the Dynamic Programming Sequence Alignment
    
        F =  TraceBackMatrix(RowIndex,ColumnIndex);
        
        switch F
            
            case 'D'
                eegEventSeq(count,1) = a(ColumnIndex-1);
                logEventSeq(count,1) = b(RowIndex-1);
                eegIndexSeq(count2,1) = ColumnIndex-1;  % Storing EegIndexSeq values of both original input Sequences
                logIndexSeq(count2,1) = RowIndex-1;
                
                ColumnIndex = ColumnIndex - 1;
                RowIndex = RowIndex - 1;
                count2 = count2 + 1;
                
            case 'L'
                 eegEventSeq(count,1) = a(ColumnIndex-1); 
                 logEventSeq(count,1) = 0;
                 ColumnIndex = ColumnIndex - 1;
                
            case 'U'
                 logEventSeq(count,1) = b(RowIndex-1);
                 eegEventSeq(count,1) = 0;
                RowIndex = RowIndex - 1;
        end
        
        count = count + 1 ;
        
end


% The Events and Index Sequenctes of EEG and Log file are upside down after
% traceback, hence reversing the sequences.

l =size(eegIndexSeq,1);
for i = 1:l
    EegIndexSeq(i,1) = eegIndexSeq(l);   % The EEG Index Sequence
    l = l-1;
end

l = size(logIndexSeq,1);
for i = 1:l
    LogIndexSeq(i,1) =  logIndexSeq(l);  % The Log Index Sequence
    l = l-1;
end

l =  size(eegEventSeq,1);
for i = 1:l
    EegEventSeq(i,1) =  eegEventSeq(l);  % The EEG Events Sequence
    
    l = l-1;
end

l = size(logEventSeq,1);
for i = 1:l
    LogEventSeq(i,1) =  logEventSeq(l);  % The Log Events Sequence

    l = l-1;
end

