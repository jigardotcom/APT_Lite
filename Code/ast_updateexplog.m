% AST_UPDATEEXPLOG() - Transform 2-digit event codes into 4-digit event codes based
%					on the minigame in which they occur.  Also produce the 
%					structures: GameStartIndices and MinigameIndices.
% Usage:
%			>> [ExpLog,GameStartIndices,MinigameIndices] = ast_updateexplog(ExpLogToUpdate)
%
% Input:
%	ExpLogToUpdate	= the ExpLog to update
%					Precondition: ExpLogToUpdate is a structure of the form generated 
%									by MakeStructure
%
%	see also: ast_makestructure.m, ast_readfile.m
%
% Author: Keith Yoder
% Copyright (c) 2010 Cornell University

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

% revision history
% ----------------
% 10/05/04 - kjy3
%   Added 'End_of_Log' check to set game back to 0 in case of crashed game
%
% 10/03/15 - kjy3
%   Now determine start command indices by examining each event's name
%   (no longer examine codes for start command identification)
%
% 10/03/15 - kjy3
%   Updated SJ_START code to 1
%   No longer distinguish between 'SJ_Level' and 'SJ_SallyAnne' in Indices
%   'name'
%
function [ExpLog,GameStartIndices,MinigameIndices] = ast_updateexplog(ExpLogToUpdate)

UpdatedExpLog = ExpLogToUpdate;
%{ 
game
    0: no game selected
    1: Maritime Defender
    2: StarJack
    3: StellarProspector
    4: Auditory Stimuli
    5: FaceOff
    6: Floater (command outside of minigame)
%}
game = 0;

%{
GameStartIndices stores the index for each of the game start commands and
    the name of that game
%}
GameStartIndices = struct('game',0,'start',0);
MinigameIndices = struct('game',0,'start',0,'end',0);

g=1; % index in GameStartIndices
k=0; % index in ExpLog
% inv: ExpLog(1..k) have been updated && start commands have been moved
% into GameStartIndices(1..g) && into MinigameIndices(1..g)
while k ~= length(UpdatedExpLog)
    k = k + 1;
    % Determine current game    
    % ----------------------
    % ASSERT: Maritime Defender start command begins
    % 'MD_MaritimeDefenderGameBegin'
    if findstr(UpdatedExpLog(k).name{1},'MD_MaritimeDefenderGameBegin')
                game=1;
                GameStartIndices(g) = struct('game','MaritimeDefender','start',k);
                MinigameIndices(g) = struct('game','MaritimeDefender','start',k,'end',0);
                g = g + 1;
                UpdatedExpLog(k).code = UpdatedExpLog(k).code + 1000;
                k = k + 1;
    % ASSERT: StarJack level and Hack start command begins 'SJ_START'
    elseif findstr(UpdatedExpLog(k).name{1},'SJ_START')
				game=2;
                GameStartIndices(g) = struct('game','StarJack','start',k);
                MinigameIndices(g) = struct('game','StarJack','start',k,'end',0);
                g = g + 1;
                UpdatedExpLog(k).code = UpdatedExpLog(k).code + 2000;
                k = k + 1;
    % ASSERT: StarJack Sally-Anne start command begins 'SJ_SAT_START'
    elseif findstr(UpdatedExpLog(k).name{1},'SJ_SAT_START')
                % if the previous game was StarJack_Level, write in an end
                % code for the previous game
                if strcmp(MinigameIndices(g-1).game,'StarJack')
                    MinigameIndices(g-1).end = k;
                end
                game=2;
                GameStartIndices(g) = struct('game','StarJack','start',k);
                MinigameIndices(g) = struct('game','StarJack','start',k,'end',0);
                g = g + 1;
                UpdatedExpLog(k).code = UpdatedExpLog(k).code + 2000;
                k = k + 1;
    % ASSERT: Stellar Prospector start command begins 'SP_Phase'
    elseif findstr(UpdatedExpLog(k).name{1},'SP_Phase')
				game=3;
                GameStartIndices(g) = struct('game','StellarProspector','start',k);
                MinigameIndices(g) = struct('game','StellarProspector','start',k,'end',0);
                g = g + 1;
                UpdatedExpLog(k).code = UpdatedExpLog(k).code + 3000;
                k = k + 1;
    % ASSERT: Auditory Stimuli start command begins 'AS_START'
    elseif findstr(UpdatedExpLog(k).name{1},'AS_START')
				game=4;
                GameStartIndices(g) = struct('game','AuditoryStimuli','start',k);
                MinigameIndices(g) = struct('game','AuditoryStimuli','start',k,'end',0);
                g = g + 1;
                UpdatedExpLog(k).code = UpdatedExpLog(k).code + 4000;
                k = k + 1;
    % ASSERT: FaceOff start command begins 'FO_START'
    elseif strcmp(UpdatedExpLog(k).name{1},'FO_START')
                game=5;
                GameStartIndices(g) = struct('game','FaceOff','start',k);
                MinigameIndices(g) = struct('game','FaceOff','start',k,'end',0);
                g=g+1;
                UpdatedExpLog(k).code = UpdatedExpLog(k).code + 5000;
                k=k+1;        
    end
        
    % Process codes in game
    % if code is an end code, store end in MinigameIndices(g-1).end and change game to 0
    if game~=0
            switch game
                case 1 %Maritime Defender
                    UpdatedExpLog(k).code = UpdatedExpLog(k).code + 1000;
                    %{ 
                      ASSERT: CoherenceEstimate is the command that occurs
                      immediately following the MD_GameSuccess or
                      MD_GameFailure
                    %}
                    % if CoherenceEstimate command, set game to 0
                    if strncmp(UpdatedExpLog(k).name,'MD_DotCoherenceEstimate',23)
                        MinigameIndices(g-1).end = k;
                        game=0;
                    end
                case 2 %StarJack
                    UpdatedExpLog(k).code = UpdatedExpLog(k).code + 2000;
                    % if end command, set game to 0
                    if strncmp(UpdatedExpLog(k).name,'SJ_SAT_END',10)
                        MinigameIndices(g-1).end = k;
                        game=0;
                    end
                case 3 % StellarProspector
                    UpdatedExpLog(k).code = UpdatedExpLog(k).code + 3000;
                    % if end command, set game to 0
                    if strncmpi(UpdatedExpLog(k).name,'SP_End',6)
                        MinigameIndices(g-1).end = k;
                        game=0;
                    end
                case 4 % AuditoryStimuli
                    UpdatedExpLog(k).code = UpdatedExpLog(k).code + 4000;
                    % if end command, set game to 0
                    if strncmp(UpdatedExpLog(k).name,'AS_END',6)
                        MinigameIndices(g-1).end = k;
                        game=0;
                    end
                case 5 % FaceOff
                    UpdatedExpLog(k).code = UpdatedExpLog(k).code + 5000;
                    % if end command, set game to 0
                    if strncmp(UpdatedExpLog(k).name,'FO_END',5)
                        MinigameIndices(g-1).end = k;
                        game=0;
                    end
            end
        % if an end_of_log code is encountered, or the beginning of a new
        % log is encountered, set game back to 0
        if strncmp(UpdatedExpLog(k).name,'End_of_Log',10) || ...
                strncmp(UpdatedExpLog(k).name,'This log was generated by build',31)
            UpdatedExpLog(k).code = 6000;
            MinigameIndices(g-1).end = k;
            game=0;
        end
    else
    % If no game, make code 6***
        UpdatedExpLog(k).code = UpdatedExpLog(k).code + 6000;
    end
end

% ensure that MinigameIndices and END indices are greater than their paired 
% START indices
for i=1:length(MinigameIndices)
    if MinigameIndices(i).end < MinigameIndices(i).start
        if i<length(MinigameIndices)
            MinigameIndices(i).end = MinigameIndices(i+1).start - 1;
        else
            MinigameIndices(i).end = length(UpdatedExpLog);
        end
    end
end


ExpLog = UpdatedExpLog;