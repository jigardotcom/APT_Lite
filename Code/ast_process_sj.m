% AST_PROCESS_SJ() - Process events for the minigame StarJack, extracting behavioural data and updating
%					EEG.event as appropriate.
% 				
% Usage:
% 			>> [UpdatedEvent,DPrimeEFTMatrix,SJBehData,logstr] = ast_process_sj(Event,CurrentExpLogIndex);
% 		else
% 			>> [UpdatedEvent,DPrimeEFTMatrix,SJBehData,logstr,newEEGIndex] = ast_process_sj(Event,CurrentExpLogIndex,...
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
%   DPrimeEFTMatrix     = if Event was for an EFT event, returns a 1x4
%                       matrix with a logical index for which response was
%                       given (a 1 for the response, 0 for all others)
%                       [HIT REJECT FALSE_ALARM MISS] 
%
%   SJBehData           = struct with the behavioural data for StarJack
%                           d'prime statistic           (DPrime)
%                           EFT Accuracy                (EFTAcc)
%                           EFT Latency                 (EFTLat)
%                           First Order Accuracy        (AccFO)
%                           First Order Latency         (LatFO)
%                           Second Order Accuracy       (AccSO)
%                           Second Order Latency        (LatSO)
%
%   logstr              = the string to log
%
%   newEEGIndex         = the current index in EEG after processing
% 
% Precondition: Event is a structure of the form generated by MakeStructure
% Precondition: If EEGIndex is supplied, there exists an instance of EEG with a valid
% 					event channel.
% 
% see also: ast_process.m, ast_process_md.m, ast_process_sp.m, ast_process_as.m
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

% Revision History
% ----------------
% 10/04/29 - kjy3
% Added logging capability
% Fixed overloaded SJ_SAT event codes and SJBehData logging

function [UpdatedEvent DPrimeEFTMatrix SJBehData logstr newEEGIndex] = ast_process_sj(Event, CurrentExpLogIndex, varargin)
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
DPrimeEFTMatrix holds the counts for the various EFT response types:
    HIT, REJECT, FALSE_ALARM, MISS
%}
DPrimeEFTMatrix = [0 0 0 0];

%{
SJBehData holds the behaviour data for StarJack
    d'prime statistic  		(DPrime)
    EFT Accuracy       		(EFTAcc)
    EFT Latency        		(EFTLat)
    First Order Accuracy	(AccFO)
    First Order Latency		(LatFO)
    Second Order Accuracy	(AccSO)
    Second Order Latency	(LatSO)
%}
SJBehData = struct('DPrime',0,'EFTAcc',0,'EFTLat',0,'AccFO',0,'LatFO',0,'AccSO',0,'LatSO',0);
SJBehData.DPrime = []; % holds the final DPrime calculation for EFT
SJBehData.EFTAcc = []; % holds EFT responses: 1 for correct, 0 for incorrect
SJBehData.EFTLat = []; % holds latency for each EFT response
SJBehData.AccFO = []; % holds SAT FirstOrder responses: 1 for correct, 0 for incorrect
SJBehData.LatFO = []; % holds latency for each SAT FirstOrder response
SJBehData.AccSO = []; % holds SAT SecondOrder responses: 1 for correct, 0 for incorrect
SJBehData.LatSO = []; % holds latency for each SAT SecondOrder response

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
        newEEGIndex = EEGIndex;
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
    EEGEventsIndex = ast_searcheeg(Code-2000,newEEGIndex);
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

if P
switch Code
    %{
    LOGICAL EVENTS
    %}
    case 2001 % SJ_START

    case 2002 % SJ_START Level=Level? Room=Room?
        
    case 2015 % SJ_MENU_INPUT_Enter
        
    case 2036 % SJ_MENU_INPUT_Left_Click

    case 2020 % SJ_END_SUCCESS Level=Levelcase ?

    case 2052 % SJ_SAT_START

    case 2053 % SJ_SAT_END

    case 2058 % SJ_SAT_INPUT_Continue

    case 2006 % SJ_MENU_INPUT_Right

    case 2007 % MenuSelectButtonPressed
        
    case 2022 % SJ_SkipTurn


    %{
    GAME EVENTS
    %}
    case 2013 % SJ_Caught_TeleportToStart
        
    case 2044 % SJ_SJ_EFT_END_FAIL
        
        
    %{
    PLAYER INPUT EVENTS
    %}
    case 2009 % SJ_Cloak_Start
        
    case 2010 % SJ_Cloak_End
    
    case 2011 % SJ_TrapPlaced
        
    case 2012 % SJ_GuardTrapped X=??? Y=???
        
    case 2014 % SJ_INPUT_Esc
        
    case 2021 % SJ_INPUT_LineOfSight_Toggle

    case 2023 % SJ_INPUT_Move_Up

    case 2024 % SJ_INPUT_Move_Down

    case 2025 % SJ_INPUT_Move_Right

    case 2026 % SJ_INPUT_Move_Left
        
    case 2031 % SJ_INPUT_PlaceTrap
        
    case 2032 % SJ_INPUT_Cloak
        
    case 2033 % SJ_INPUT Interact

    case 2034 % SJ_INPUT_LeftClick X=??? Y=???

    %{
    EFT EVENTS
    %}
    case 2038 % SJ_EFT_Stimulus_Presented Key=Key?? Figure=Figure??
        % find next HIT, REJECT, FALSE_ALARM or MISS
        EFTProbe = ExpLogIndex;
        %ASSERT: EXPLOG(ExpLogIndex).code == 2038
        %inv: events EXPLOG(ExpLogIndex+1..EFTProbe) are not H R FA or M
        while EFTProbe<length(EXPLOG)
            EFTProbe = EFTProbe + 1;
            NextCode = EXPLOG(EFTProbe).code;
            switch NextCode
                case 2039 %HIT
                    UpdatedEvent.code = 2139;
                    UpdatedEvent.name = 'SJ_EFT_PRESENT_HIT';                
                    SJBehData.EFTAcc = 1;
                    break;
                case 2040 %REJECT
                    UpdatedEvent.code = 2140;
                    UpdatedEvent.name = 'SJ_EFT_PRESENT_REJECT';                
                    SJBehData.EFTAcc = 1;
                    break;
                case 2041 %FALSE_ALARM
                    UpdatedEvent.code = 2141;
                    UpdatedEvent.name = 'SJ_EFT_PRESENT_FALSE_ALARM';               
                    SJBehData.EFTAcc = 0;
                    break;
                case 2042 %MISS
                    UpdatedEvent.code = 2142;
                    UpdatedEvent.name = 'SJ_EFT_PRESENT_MISS';                
                    SJBehData.EFTAcc = 0;
                    break;
            end
        end
        
        if EFTProbe == length(EXPLOG)
           UpdatedEvent.code = 2991;
           UpdatedEvent.name = 'SJ_EFT_No_Response_Found';
        else 
            %record duration
            EFTDuration = ast_getduration(ExpLogIndex,EFTProbe);
            SJBehData.EFTLat = EFTDuration;
            
            %update the event's name
            UpdatedEvent.name = strcat([Name,' ReplacedBy=',UpdatedEvent.name]);
            
            %append duration
            UpdatedEvent.name = strcat(UpdatedEvent.name,' Duration=',...
                num2str(EFTDuration));
        end
    
    case 2039 % HIT
        DPrimeEFTMatrix = [1 0 0 0];
    case 2040 % REJECT
        DPrimeEFTMatrix = [0 1 0 0];
    case 2041 % FALSE_ALARM
        DPrimeEFTMatrix = [0 0 1 0];
    case 2042 % MISS
        DPrimeEFTMatrix = [0 0 0 1];
    case 2046 % SJ_EFT_INPUT_NoMatch
	
    case 2047 % SJ_EFT_INPUT_Match

    case 2048 % SJ_EFT_INPUT_Proceed

    case 2049 % SJ_EFT_START
        % find next 2050 - SUCCESS/FAIL
        % rescore to 2051 if SUCCESS, 2052 if FAIL
        EFTResult = 0;
        k = ExpLogIndex;
        %ASSERT: EXPLOG(ExpLogIndex).code == 2049
        %inv: EXPLOG(ExpLogIndex+1..k) does not contain SUCCESS/FAIL
        while k<length(EXPLOG) && EFTResult == 0
            k=k+1;
            NCode = EXPLOG(k).code;
            NName = EXPLOG(k).name;
            if NCode == 2050
                if strncmpi(NName,'success',7)
                    UpdatedEvent.code = 2151;
                    UpdatedEvent.name = 'SJ_EFT_SUCCESS';
                    EFTResult = 1;
                else
                    UpdatedEvent.code = 2152;
                    UpdatedEvent.name = 'SJ_EFT_FAIL';
                    EFTResult = 2;
                end
            end
        end
        
        if k == length(EXPLOG)
           UpdatedEvent.code = 2992;
           UpdatedEvent.name = 'SJ_EFT_Outcome_Not_Found';
        else 
            %record duration
            EFTDuration = ast_getduration(ExpLogIndex,k);
            SJBehData.EFTLat = EFTDuration;
            
            %update the event's name
            UpdatedEvent.name = strcat([Name,' ReplacedBy=',UpdatedEvent.name]);
            
            %append duration
            UpdatedEvent.name = strcat(UpdatedEvent.name,' Duration=',...
                num2str(EFTDuration));
        end

    case 2050 % SJ_EFT_END_SUCCESS/FAIL
        

    %{
    THEORY OF MIND EVENTS 
    %}
    case 2055 % SJ_SAT_Video_Stop

    case 2059 % SJ_SAT_VideoStart_CargoDrop Planet=RIGHT

    case 2060 % SJ_SAT_VideoStart_Pirate_Drop Planet=BOTTOM

    case 2061 % SJ_SAT_VideoStart_Pirate_Theft Planet=RIGHT

    case 2062 % SJ_SAT_VideoStart_Pirate_NoTheft Planet=BOTTOM

    case 2064 % SJ_SAT_INPUT_Response_Top

    case 2065 % SJ_SAT_INPUT_Response_Bottom

    case 2066 % SJ_SAT_INPUT_Response_Left

    case 2067 % SJ_SAT_INPUT_Response_Right

    case 2068 % SJ_SAT_INPUT_NoTheft_<Correct/Incorrect>
        % if Name is SJ_SAT_INPUT_NoTheft_Incorrect, change 
        %   UpdatedEvent.code to 2069
        if ~isempty(regexp(Name,'Incorrect','once'))
            UpdatedEvent.code = 2069;
        end

    case 2070 % SJ_SAT_FirstOrder_<Scan/Theft>_Correct
        % if Name is SJ_SAT_INPUT_Theft_Correct, change 
        %   Updated.Event.code to 2170
        if ~isempty(regexp(Name,'Theft','once'))
            UpdatedEvent.code = 2170;
        end
        
    case 2071 % SJ_SAT_FirstOrder_Theft_IncorrectTrueLocation

    case 2072 % SJ_SAT_FirstOrder_Theft_IncorrectOtherLocation

    case 2076 % SJ_SAT_SecondOrder_NoTheft_<Correct/Incorrect>
        % if Name is SJ_SAT_SecondOrder_NoTheft_Incorrect, change
        %   UpdatedEvent.code to 2077
        if ~isempty(regexp(Name,'Incorrect','once'))
            UpdatedEvent.code = 2077;
        end

    case 2078 % SJ_SAT_SecondOrder_<Scan/Theft>_Correct
        % if Name is SJ_SAT_SecondOrder_Theft_Correct, change 
        %   Updated.Event.code to 2178
        if ~isempty(regexp(Name,'Theft','once'))
            UpdatedEvent.code = 2178;
        end

    case 2080 % SJ_SAT_SecondOrder_Theft_IncorrectOtherLocation

    case 2084 % SJ_SAT_(First|Second)Order_Question_Presented
        % determine whether question was FirstOrder or SecondOrder
        questionorder = regexp(Name,'(?<=T_)\w*Order','match');
        if isempty(questionorder)
            error('Problem extracting question order at %d\n',CurrentExpLogIndex);
        end
        if iscell(questionorder)
            questionorder = questionorder{1};
        end
        
        % find next event of the same order
        i=ExpLogIndex;
        responseorder = [];
        % inv: EXPLOG(ExpLogIndex+1..i) do not contain order, if order is
        % found, store it in score
        while i<length(EXPLOG) && isempty(responseorder)
            i=i+1;
            responseorder = regexp(EXPLOG(i).name,'(?<=T_)\w*Order','match');
            if ~isempty(responseorder)
                if iscell(responseorder)
                    responseorder = responseorder{1};
                end
            end
        end
        
        responsename = EXPLOG(i).name;
        if iscell(responsename)
            responsename = responsename{1};
        end
        
        % based on the name of the found event, rename UpdatedEvent.code
        % and UpdatedEvent.name and update AccFO or AccSO
        
        % FirstOrder
        if strncmpi(responsename,'SJ_SAT_FirstOrder_NoTheft_Correct',30)
            SJBehData.AccFO = 1;
            UpdatedEvent.code = 2301;
            UpdatedEvent.name = 'SJ_SAT_FirstOrder_NoTheft_Response_Correct';
        elseif strncmpi(responsename,'SJ_SAT_FirstOrder_NoTheft_Incorrect',30)
            SJBehData.AccFO = 0;
            UpdatedEvent.code = 2302;
            UpdatedEvent.name = 'SJ_SAT_FirstOrder_NoTheft_Response_Incorrect';
       elseif strncmpi(responsename,'SJ_SAT_FirstOrder_Theft_Correct',30)
            SJBehData.AccFO = 1;
            UpdatedEvent.code = 2303;
            UpdatedEvent.name = 'SJ_SAT_FirstOrder_Theft_Response_Correct';
        elseif strncmpi(responsename, 'SJ_SAT_FirstOrder_Theft_IncorrectTrueLocation',30)
            SJBehData.AccFO = 0;
            UpdatedEvent.code = 2304;
            UpdatedEvent.name = 'SJ_SAT_FirstOrder_Theft_Response_IncorrectTrueLocation';
        elseif strncmpi(responsename, 'SJ_SAT_FirstOrder_Theft_IncorrectOtherLocation',30)
            SJBehData.AccFO = 0;
            UpdatedEvent.code = 2305;
            UpdatedEvent.name = 'SJ_SAT_FirstOrder_Theft_Response_IncorrectOtherLocation';
        elseif strncmpi(responsename, 'SJ_SAT_FirstOrder_Scan_Correct',30)
            SJBehData.AccFO = 1;
            UpdatedEvent.code = 2306;
            UpdatedEvent.name = 'SJ_SAT_FirstOrder_Scan_Response_Correct';
        elseif strncmpi(responsename, 'SJ_SAT_FirstOrder_Scan_IncorrectFakeLocation',30)
            SJBehData.AccFO = 0;
            UpdatedEvent.code = 2307;
            UpdatedEvent.name = 'SJ_SAT_FirstOrder_Scan_Response_IncorrectFakeLocation';
        elseif strncmpi(responsename, 'SJ_SAT_FirstOrder_Scan_IncorrectOtherLocation',30)
            SJBehData.AccFO = 0;
            UpdatedEvent.code = 2308;
            UpdatedEvent.name = 'SJ_SAT_FirstOrder_Scan_Response_IncorrectOtherLocation';

        % SecondOrder 
        elseif strncmpi(responsename, 'SJ_SAT_SecondOrder_NoTheft_Correct',30)
            SJBehData.AccSO = 1;
            UpdatedEvent.code = 2311;
            UpdatedEvent.name = 'SJ_SAT_SecondOrder_NoTheft_Response_Correct';
        elseif strncmpi(responsename, 'SJ_SAT_SecondOrder_NoTheft_Incorrect',30)
            SJBehData.AccSO = 0;
            UpdatedEvent.code = 2312;
            UpdatedEvent.name = 'SJ_SAT_SecondOrder_NoTheft_Response_Incorrect';
        elseif strncmpi(responsename, 'SJ_SAT_SecondOrder_Theft_Correct',30)
            SJBehData.AccSO = 1;
            UpdatedEvent.code = 2313;
            UpdatedEvent.name = 'SJ_SAT_SecondOrder_Theft_Response_Correct';
        elseif strncmpi(responsename, 'SJ_SAT_SecondOrder_Theft_IncorrectTrueLocation',30)
            SJBehData.AccSO = 0;
            UpdatedEvent.code = 2314;
            UpdatedEvent.name = 'SJ_SAT_SecondOrder_Theft_Response_IncorrectTrueLocation';
        elseif strncmpi(responsename, 'SJ_SAT_SecondOrder_Theft_IncorrectOtherLocation',30)
            SJBehData.AccSO = 0;
            UpdatedEvent.code = 2315;
            UpdatedEvent.name = 'SJ_SAT_SecondOrder_Theft_Response_IncorrectOtherLocation';
        elseif strncmpi(responsename, 'SJ_SAT_SecondOrder_Scan_IncorrectTrueLocation',30)
            SJBehData.AccSO = 0;
            UpdatedEvent.code = 2316;
            UpdatedEvent.name = 'SJ_SAT_SecondOrder_Scan_Response_IncorrectTrueLocation';
        elseif strncmpi(responsename, 'SJ_SAT_SecondOrder_Scan_IncorrectOtherLocation',30)
            SJBehData.AccSO = 0;
            UpdatedEvent.code = 2317;
            UpdatedEvent.name = 'SJ_SAT_SecondOrder_Scan_Response_IncorrectOtherLocation';
        elseif strncmpi(responsename, 'SJ_SAT_SecondOrder_Scan_Correct',30)
            SJBehData.AccSO = 1;
            UpdatedEvent.code = 2318;
            UpdatedEvent.name = 'SJ_SAT_SecondOrder_Scan_Response_Correct';
        end
        
        %record duration
        SATDuration = ast_getduration(ExpLogIndex,i);
        if strcmp(questionorder,'FirstOrder')
            SJBehData.LatFO = SATDuration;
        else
            SJBehData.LatSO = SATDuration;
        end
        
        %update the event's name
        UpdatedEvent.name = strcat([Name,' ReplacedBy=',UpdatedEvent.name]);

        %append duration
        UpdatedEvent.name = strcat(UpdatedEvent.name,' Duration=',...
            num2str(SATDuration));

        
    case 2085 % SJ_SAT_VideoStart_Cruiser_NoScan|SJ_SAT_VideoStart_Cruiser_View_Theft
        % if Name is SJ_SAT_VideoStart_Cruiser_View_Theft, change
        %   UpdatedEvent.code to 2086
        if ~isempty(regexp(Name,'Theft','once'))
            UpdatedEvent.code = 2086;
        end
        

    case 2087 % SJ_SAT_VideoStart_Cruiser_View_NoTheft

    otherwise 
        fprintf('ERROR: Unknown event encountered by ProcessSJ\n');
        fprintf('%d - %s at %d in ExpLog\n',Code,Name,ExpLogIndex);
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
    