% AST_PROCESS_SP() - Process events for the minigame Stellar Prospector, extracting behavioural data and
%					updating EEG.event as appropriate.
% 				
% Usage:
% 			>> [UpdatedEvent,SPBehData,logstr] = ast_process_sp(Event,CurrentExpLogIndex);
% 		else
% 			>> [UpdatedEvent,SPBehData,logstr,newEEGIndex] = ast_process_sp(Event,CurrentExpLogIndex,...
%																'key1','val1',...);
% 
% Inputs:
% 	Event				= the event from ExpLog to process
% 	
% 	CurrentExpLogIndex	= the current index in ExpLog
% 
% 	(optional)
% 	'EEGIndex'	= the current index in EEG.event
%                       {default is empty = no EEG}
% 
%   'log'               = 'on'|'off' if 'on', return a string to write to a
%                       log file, otherwise do nothing
%                       {default is empty == off}
%
% Output:
%   UpdatedEvent        = the event from ExpLog with code and name updated
%
%   newEEGIndex         = the current index in EEG after processing
%
%   logstr              = the string to log
% 
% Precondition: Event is a structure of the form generated by MakeStructure
% Precondition: If EEGIndex is supplied, there exists an instance of EEG with a valid
% 					event channel.
% 
% see also: ast_process.m, ast_process_md.m, ast_process_sj.m,
%           ast_process_as.m, sp_compile.m
% 
% Author: Kristen Knodel and Keith Yoder
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

% Revision History
% ----------------
% 10/04/29 - kjy3
% Added logging capability

function [UpdatedEvent SPBehData logstr newEEGIndex] = ast_process_sp(Event, CurrentExpLogIndex, varargin)
global EXPLOG
% initialize variables
EEGIndex = []; % empty unless EEGIndex is provided - then then current index in EEG
newEEGIndex = []; % empty unless EEGIndex was provided - then the index of the processed code in EEG
logtoggle = []; % 0 if 'off', 1 if 'on'
logstr = []; % holds the string to log
P=1; % 1 if given code should be updated, 0 otherwise

UpdatedEvent = Event;
Code = Event.code;
Name = Event.name;
ExpLogIndex = CurrentExpLogIndex;

%{
SPBehData holds the behavioral data for Stellar Prospector
    Cued Peripheral Response Accuracy 		(PAccC)
    Cued Peripheral Response Latency  		(PLatC)
    Non-Cued Peripheral Response Accuracy	(PAccN)
    Non-Cued Peripheral Response Latency	(PLatN)
    Central Response Accuracy    			(CAcc)
    Central Response Latency     			(CLat)
%}
SPBehData = struct('PAccC',0,'PLatC',0,'PAccN',0,'PLatN',0,'CAcc',0,'CLat',0);
SPBehData.PAccC = []; % holds cued, peripheral responses: 1 for correct, 0 for incorrect
SPBehData.PLatC = []; % holds latency for each cued, peripheral response
SPBehData.PAccN = []; % holds non-cued, peripheral responses: 1 for correct, 0 for incorrect
SPBehData.PLatN = []; % holds latency for each non-cued, peripheral response
SPBehData.CAcc = []; % holds central responses: 1 for correct, 0 for incorrect
SPBehData.CLat = []; % holds latency for each central response

% location of current cue
%   empty if no cue has been set
%   if a new phase starts, set cue empty
persistent cuedSector

% the current phase
%   set when phase begins
persistent Phase

% if Phase has not been set, set it to 1
if isempty(Phase)
    Phase=1;
end

v=0;
% inv: varargin(1..v) have been examined and stored in the appropriate
% local variable
while v<length(varargin)
    v=v+1;
    if isequal(varargin{v},'EEGIndex'),v=v+1;EEGIndex = varargin{v}; end;
    if isequal(varargin{v},'log'),v=v+1;logtoggle = varargin{v}; end;
end

% if logtoggle is set to 'on', replace logtoggle with 1
if ~isempty(logtoggle) && strcmp(logtoggle,'on')
    logtoggle = 1;
else % otherwise set logtoggle to 0
    logtoggle = 0;
end

% if Name is a cell, extract the data from within the cell
% ASSERT: if Name is a cell, data within it is type 'char'
if iscell(Name)
    Name = Name{1};
end

% if Code is a cell, extract the data from within the cell
% ASSERT: if Code is a cell, data within it is type 'double'
if iscell(Code)
    Code = Code{1};
end
% if code is multiple of 1000, return  (0 codes do not appear in EEG file)
if mod(Code,1000)==0;
    if ~isempty(varargin)
        newEEGIndex=EEGIndex;
        % if logtoggle is 'on', return a string to log
        if logtoggle
            logstr = sprintf('Code %d at %d in ExpLog ends in 0 - EEG not updated\n',...
                Code,ExpLogIndex);
        end
    end
    P=0;
end

%if EEG exists, update the code and name
if P && ~isempty(EEGIndex)
    newEEGIndex = EEGIndex;

    % update the 2-digit code in EEG.event to the 4-digit code in ExpLog
    EEGEventsIndex = ast_searcheeg(Code-3000,newEEGIndex);
    % if Code is not found (e.g. EEGEventsIndex == -1), skip it
    if EEGEventsIndex==-1
        fprintf('Skipping code %d:%s\n',Code,Name);
        % if logtoggle is 'on', return a string to log
        if logtoggle
            logstr = sprintf('Skipping code %d:%s\n',Code,Name);
        end
        P=0;
    else % otherwise update the event in EEG
        % if the event is an 'ignore' event, remove it from EEG.event,
        % decrease the newEEGIndex by 1, and do not process the code
        if strncmpi(Name,'ignore',6)
            P=0;
            EEGEventsIndex = EEGEventsIndex - 1;
            removeTest = ast_removeevent(EEGEventsIndex);
            if removeTest==0
                error('astropolis:ast_process_md:RemoveEventFail',...
                    'Attempted to remove %d from EEG.event(%d)\n',...
                Code,EEGEventsIndex);
            end
        end
        newEEGIndex = EEGEventsIndex;
    end
end
% process the code
if P
    switch Code
        

    %{
        LOGICAL EVENTS
    %}
    case 3009 % SP_Phase1Begin
        % reset the cuedSector
        cuedSector=[];
        % set Phase
        Phase = 1;

    case 3010 % SP_Phase2Begin
        % reset the cuedSector
        cuedSector=[];
        % set Phase
        Phase = 2;

    case 3011 % SP_Phase3Begin
        % reset the cuedSector
        cuedSector=[];
        % set Phase
        Phase = 3;

    case 3012 % SP_End
        % reset the cuedSector
        cuedSector=[];
        
    case 3016 % SP_CueChange Sector=???
        % store the sector
        Sector = regexp(Name,'(?<=r=)\d{1}','match');
        cuedSector = str2double(Sector{1});
        
        % update the code:
        %   319x, where x is the sector that the cue has moved to
        UpdatedEvent.code = 3190 + cuedSector;
        UpdatedEvent.name = strcat('SP_CueChange_into_sector_',num2str(cuedSector));
        
    %{
        PERIPHERAL EVENTS
    %}
    case 3001 % SP_PeripheralStimulusResponsePressed
        % scored spawn codes
        scoredstims = [3301,3311,3321,3331,...
            3302,3312,3322,3332,...
            3303,3313,3323,3333,...
            3401,3411,3421,3431,...
            3402,3412,3422,3432,...
            3403,3413,3423,3433];
        % search backwards for the first scored stim spawn presentation
        probe = ExpLogIndex;
        answer = -1;
        % inv: EXPLOG probe..ExpLogIndex do not contain a scoredstim
        while probe>1 && answer==-1
            probe=probe-1;
            pcode = EXPLOG(probe).code;
            % if pcode is a scored stim, add 4 to the code to convert from 
            % presentation to response
            try test = ismember(pcode,scoredstims);
                if test
                    answer = pcode+4;
                end
            catch ME1
                fprintf('Problem at EXPLOG(%d).code:\n',probe);
                assignin('base','PROBLEMCODE',EXPLOG(probe));
                error('ProcessSP:BadCode','Bad Code\n');
            end
                
        end
        % if no previous scored stim was found, score it as such
        if answer==-1;
            answer = 555;
            UpdatedEvent.code = 3993;
            UpdatedEvent.name = 'SP_PeripheralStimulusSpawnNotFound';
        end
            
        % if a presentation was found, update the duration and event data
        % rescore event code corresponding to location of sector
        if answer~=555
            % get duration
            Duration = ast_getduration(ExpLogIndex,probe);
            
            % Update EXPLOG/EEG.event
            UpdatedEvent.code = answer;
            
            % based on the new code, update the code name
            switch answer
                case 3305	
                    UpdatedEvent.name='SP_PeripheralCuedHitRes_Sector0_Phase1';
                case 3315	
                    UpdatedEvent.name='SP_PeripheralCuedHitRes_Sector1_Phase1';
                case 3325	
                    UpdatedEvent.name='SP_PeripheralCuedHitRes_Sector2_Phase1';
                case 3335	
                    UpdatedEvent.name='SP_PeripheralCuedHitRes_Sector3_Phase1';
                case 3306	
                    UpdatedEvent.name='SP_PeripheralCuedHitRes_Sector0_Phase2';
                case 3316	
                    UpdatedEvent.name='SP_PeripheralCuedHitRes_Sector1_Phase2';
                case 3326	
                    UpdatedEvent.name='SP_PeripheralCuedHitRes_Sector2_Phase2';
                case 3336	
                    UpdatedEvent.name='SP_PeripheralCuedHitRes_Sector3_Phase2';
                case 3307	
                    UpdatedEvent.name='SP_PeripheralCuedHitRes_Sector0_Phase3';
                case 3317	
                    UpdatedEvent.name='SP_PeripheralCuedHitRes_Sector1_Phase3';
                case 3327	
                    UpdatedEvent.name='SP_PeripheralCuedHitRes_Sector2_Phase3';
                case 3337	
                    UpdatedEvent.name='SP_PeripheralCuedHitRes_Sector3_Phase3';
                case 3405	
                    UpdatedEvent.name='SP_PeripheralNonCuedHitRes_Sector0_Phase1';
                case 3415	
                    UpdatedEvent.name='SP_PeripheralNonCuedHitRes_Sector1_Phase1';
                case 3425	
                    UpdatedEvent.name='SP_PeripheralNonCuedHitRes_Sector2_Phase1';
                case 3435	
                    UpdatedEvent.name='SP_PeripheralNonCuedHitRes_Sector3_Phase1';
                case 3406	
                    UpdatedEvent.name='SP_PeripheralNonCuedHitRes_Sector0_Phase2';
                case 3416	
                    UpdatedEvent.name='SP_PeripheralNonCuedHitRes_Sector1_Phase2';
                case 3426	
                    UpdatedEvent.name='SP_PeripheralNonCuedHitRes_Sector2_Phase2';
                case 3436	
                    UpdatedEvent.name='SP_PeripheralNonCuedHitRes_Sector3_Phase2';
                case 3407	
                    UpdatedEvent.name='SP_PeripheralNonCuedHitRes_Sector0_Phase3';
                case 3417	
                    UpdatedEvent.name='SP_PeripheralNonCuedHitRes_Sector1_Phase3';
                case 3427	
                    UpdatedEvent.name='SP_PeripheralNonCuedHitRes_Sector2_Phase3';
                case 3437	
                    UpdatedEvent.name='SP_PeripheralNonCuedHitRes_Sector3_Phase3';
                otherwise
                    fprintf('Unknown event found at %d: %d\n',ExpLogIndex,answer);
            end
            
            %update the event's name
            UpdatedEvent.name = strcat([Name,' ReplacedBy=',UpdatedEvent.name]);
            
            %append duration
            UpdatedEvent.name = strcat(UpdatedEvent.name,' Duration=',...
                num2str(Duration));

        end

    case 3002 % SP_CentralStimulusResponsePressed
        % scored spawn codes
        scoredstims = [3511,3512,3513];
        
        % search backwards for the first scored stim spawn presentation
        probe = ExpLogIndex;
        answer = -1;
        % inv: EXPLOG probe..ExpLogIndex do not contain a scoredstim
        while probe>1 && answer==-1
            probe=probe-1;
            pcode = EXPLOG(probe).code;
            % if pcode is a scored stim, add 4 to the code to convert from 
            % presentation to response
            if ismember(pcode,scoredstims)
                answer = pcode+4;
            end
        end
        % if no previous scored stim was found, score it as such
        if answer==-1;
            answer = 444;
            UpdatedEvent.code = 3994;
            UpdatedEvent.name = 'SP_CentralStimulusSpawnNotFound';
        end
            
        % if a presentation was found, update the duration and event data
        % rescore event code corresponding to location of sector
        if answer~=444
            % get duration
            Duration = ast_getduration(ExpLogIndex,probe);
            
            % Update EXPLOG/EEG.event
            UpdatedEvent.code = answer;
            
            % update the duration and event data
            if answer~=777
                % get duration
                Duration = ast_getduration(ExpLogIndex,probe);
                % Update EXPLOG/EEG.event
                switch answer
                    case 3515
                        UpdatedEvent.name = 'SP_CentralHitRes_Phase1';
                    case 3516
                        UpdatedEvent.name = 'SP_CentralHitRes_Phase2';
                    case 3517
                        UpdatedEvent.name = 'SP_CentralHitRes_Phase3';
                end
            end
            
            %update the event's name
            UpdatedEvent.name = strcat([Name,' ReplacedBy=',UpdatedEvent.name]);
            
            %append duration
            UpdatedEvent.name = strcat(UpdatedEvent.name,' Duration=',...
                num2str(Duration));
        end

    case 3013 % SP_PeripheralStimulusSpawn 
        cue = -1; % location of cue; -1 if no cue is active
        % determine cue location
        if ~isempty(cuedSector) % cue has been set
            cue = cuedSector;
        end
        % determine sector of stimulus
        Sector = regexp(Name,'(?<=r=)\d{1}','match');
        Sector = str2double(Sector{1});
            
        % search for next response and rescore accordingly:
        %   3001 - SP_PeripheralStimulusResponsePressed - score as correct
        %   3017 - SP_MissedPeripheralStimulus - score as incorrect
        answer = -1;
        probe = ExpLogIndex;
        % ASSERT: EXPLOG(ExpLogIndex) is 3013 - SP_PeripheralStimulusSpawn
        % inv: events ExpLogIndex..probe are not 3001 or 3017
        while probe<length(EXPLOG) && answer == -1
            probe=probe+1;
            [NCode] = EXPLOG(probe).code;
            if NCode == 3001 % score as correct
                answer = 1; % HIT
            elseif NCode == 3017 % score as incorrect
                answer = 0; % MISS
            end
        end
        % if the code was not found, score it as such
        if answer==-1
            answer = 666;
            UpdatedEvent.code = 3991;
            UpdatedEvent.name = 'SP_PeripheralResponseNotFound';
        end

        % if a response was found, update the duration and event data
        % rescore event code corresponding to location of sector
        if answer~=666
            % get duration
            Duration = ast_getduration(ExpLogIndex,probe);
            
            % get behavioural data
            % if Sector and cue match, process as "cued"
            if Sector == cue
                % if answer is 1, score as correct
                if answer
                    SPBehData.PAccC = 1;
                else
                    SPBehData.PAccC = 0;
                end
                SPBehData.PLatC = Duration;
            else % process as "non-cued"
                % if answer is 1, score as correct
                if answer
                    SPBehData.PAccN = 1;
                else
                    SPBehData.PAccN = 0;
                end
                SPBehData.PLatN = Duration;
            end
            
            % Update SPBehData and EXPLOG/EEG.event
            % Rescore the response according to the follow scheme:
            %   The first digit is always 3 (signifiying the game SP)
            %   For the second digit:
            %       3 - if cued
            %       4 - if not-cued
            %   For the third digit:
            %       if HIT, the sector in which the cue occurred
            %       if MISS, 5
            %   For the fourth digit:
            %       the phase of SP in which the response occurred
            
            % add the first digit (3)
            Response = 3000;
            % determine the second digit (if cued 3 - else 4)
            if Sector == cue 
                Response = Response + 300;
            else
                Response = Response + 400; 
            end
            
            % add the third digit (if HIT, sector - else 5)
            if answer
                Response = Response + (Sector * 10);
            else
                Response = Response + 50;
            end
            
            % add the fourth digit (phase of SP)
            Response = Response + Phase;
            
            % Update EXPLOG/EEG.event
            UpdatedEvent.code = Response;
            
            % based on the new code, update the code name
            switch Response
                case 3301	
                    UpdatedEvent.name='SP_PeripheralCuedHit_Sector0_Phase1';
                case 3311	
                    UpdatedEvent.name='SP_PeripheralCuedHit_Sector1_Phase1';
                case 3321	
                    UpdatedEvent.name='SP_PeripheralCuedHit_Sector2_Phase1';
                case 3331	
                    UpdatedEvent.name='SP_PeripheralCuedHit_Sector3_Phase1';
                case 3351	
                    UpdatedEvent.name='SP_PeripheralCuedMiss_Phase1';
                case 3302	
                    UpdatedEvent.name='SP_PeripheralCuedHit_Sector0_Phase2';
                case 3312	
                    UpdatedEvent.name='SP_PeripheralCuedHit_Sector1_Phase2';
                case 3322	
                    UpdatedEvent.name='SP_PeripheralCuedHit_Sector2_Phase2';
                case 3332	
                    UpdatedEvent.name='SP_PeripheralCuedHit_Sector3_Phase2';
                case 3352	
                    UpdatedEvent.name='SP_PeripheralCuedMiss_Phase2';
                case 3303	
                    UpdatedEvent.name='SP_PeripheralCuedHit_Sector0_Phase3';
                case 3313	
                    UpdatedEvent.name='SP_PeripheralCuedHit_Sector1_Phase3';
                case 3323	
                    UpdatedEvent.name='SP_PeripheralCuedHit_Sector2_Phase3';
                case 3333	
                    UpdatedEvent.name='SP_PeripheralCuedHit_Sector3_Phase3';
                case 3353	
                    UpdatedEvent.name='SP_PeripheralCuedMiss_Phase3';
                case 3401	
                    UpdatedEvent.name='SP_PeripheralNonCuedHit_Sector0_Phase1';
                case 3411	
                    UpdatedEvent.name='SP_PeripheralNonCuedHit_Sector1_Phase1';
                case 3421	
                    UpdatedEvent.name='SP_PeripheralNonCuedHit_Sector2_Phase1';
                case 3431	
                    UpdatedEvent.name='SP_PeripheralNonCuedHit_Sector3_Phase1';
                case 3451	
                    UpdatedEvent.name='SP_PeripheralNonCuedMiss_Phase1';
                case 3402	
                    UpdatedEvent.name='SP_PeripheralNonCuedHit_Sector0_Phase2';
                case 3412	
                    UpdatedEvent.name='SP_PeripheralNonCuedHit_Sector1_Phase2';
                case 3422	
                    UpdatedEvent.name='SP_PeripheralNonCuedHit_Sector2_Phase2';
                case 3432	
                    UpdatedEvent.name='SP_PeripheralNonCuedHit_Sector3_Phase2';
                case 3452	
                    UpdatedEvent.name='SP_PeripheralNonCuedMiss_Phase62';
                case 3403	
                    UpdatedEvent.name='SP_PeripheralNonCuedHit_Sector0_Phase3';
                case 3413	
                    UpdatedEvent.name='SP_PeripheralNonCuedHit_Sector1_Phase3';
                case 3423	
                    UpdatedEvent.name='SP_PeripheralNonCuedHit_Sector2_Phase3';
                case 3433	
                    UpdatedEvent.name='SP_PeripheralNonCuedHit_Sector3_Phase3';
                case 3453	
                    UpdatedEvent.name='SP_PeripheralNonCuedMiss_Phase3';
            end
            
            %update the event's name
            UpdatedEvent.name = strcat([Name,' ReplacedBy=',UpdatedEvent.name]);
            
            %append duration
            UpdatedEvent.name = strcat(UpdatedEvent.name,' Duration=',...
                num2str(Duration));
        end

    %{
        CENTRAL EVENTS
    %}
    case 3014 % SP_CentralStimulusSpawn Presented
       
        % search for next response and rescore accordingly:
        %   3002 - SP_CentralStimulusResponsePressed - score as correct
        %   3018 - SP_MissedSentralStimulus - score as incorrect
        answer = -1;
        probe = ExpLogIndex;
        % ASSERT: EXPLOG(ExpLogIndex) is 3014 - SP_CentralStimulusSpawn
        % inv: events ExpLogIndex..probe are not 3001 or 3017
        while probe<length(EXPLOG) && answer == -1
            probe=probe+1;
            [NCode] = EXPLOG(probe).code;
            if NCode == 3002 % score as correct
                answer = 1;
            elseif NCode == 3018 % score as incorrect
                answer = 0;
            end
        end
        % if the code was not found, score it as such
        if answer==-1
            answer = 777;
            UpdatedEvent.code = 3992;
            UpdatedEvent.name = 'SP_CentralResponseNotFound';
        end
        
        % if a response was found, update the duration and event data
        if answer~=777
            % get duration
            Duration = ast_getduration(ExpLogIndex,probe);
            % Update SPBehData and EXPLOG/EEG.event
            
            % Rescore the response according to the follow scheme:
            %   The first two digits are always 3 5
            %   For the third digit:
            %       if HIT, 1
            %       if MISS, 0
            %   For the fourth digit:
            %       the phase of SP in which the response occurred 
            if answer
                SPBehData.CAcc = 1;
                UpdatedEvent.code = 3510 + Phase;
                switch UpdatedEvent.code
                    case 3511
                        UpdatedEvent.name = 'SP_CentralHit_Phase1';
                    case 3512
                        UpdatedEvent.name = 'SP_CentralHit_Phase2';
                    case 3513
                        UpdatedEvent.name = 'SP_CentralHit_Phase3';
                end
            else
                SPBehData.CAcc = 0;
                UpdatedEvent.code = 3500 + Phase;
                switch UpdatedEvent.code
                    case 3501
                        UpdatedEvent.name = 'SP_CentralMiss_Phase1';
                    case 3502
                        UpdatedEvent.name = 'SP_CentralMiss_Phase2';
                    case 3503
                        UpdatedEvent.name = 'SP_CentralMiss_Phase3';
                end
            end
            SPBehData.CLat = Duration;
                        
            %update the event's name
            UpdatedEvent.name = strcat([Name,' ReplacedBy=',UpdatedEvent.name]);
            
            %append duration
            UpdatedEvent.name = strcat(UpdatedEvent.name,' Duration=',...
                num2str(Duration));
        end
        
    %{
        DISTRACTOR EVENTS
    %}
    case 3015 %distractor stimulus presented
        
    end % switch end
         
end

% if EEG exists update the event structure
if ~isempty(EEGIndex)
    %replace the code in EEG.events with its new value
    ast_updateEvent(newEEGIndex,UpdatedEvent.code,'name',UpdatedEvent.name);
end

% if logtoggle is 'on' and a logstr has not been set, update logstr to the new
% code
if logtoggle && isempty(logstr)
    % if either Event.code, UpdatedEvent.code or UpdatedEvent.name is a
    % cell, extract the data contained within
    if iscell(Code)
        Code = Code{1};
    end
    if iscell(UpdatedEvent.code)
        UpdatedEvent.code = UpdatedEvent.code{1};
    end
    if iscell(UpdatedEvent.name)
        UpdatedEvent.name = UpdatedEvent.name{1};
    end
    logstr = sprintf('Event at %d (%d) replaced by %d\t%s\n',...
       ExpLogIndex,Code,UpdatedEvent.code,UpdatedEvent.name);
end
