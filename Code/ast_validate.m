% AST_VALIDATE() - Validate an ExpLog to ensure that it is ready for processing
%
% Usage:
%		>> success = ast_validate(ExpLog);
%
% Input:
%	ExpLog	= the ExpLog to be validated
%
% Ensures that:
%   (0) All codes are four digits
% 	(1) Build is at least 2009/02/23
% 	(2) Log ends with an End_of_log command
% 	(3) Minigame start commands have end commands
% 	(4) Only game-valid events exist in ExpLog
% 	(5) MinigameIndices contains start and end commands
% 
% See also: ast_makestructure.m, ast_readfile.m, ast_updateexplog
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

function success = ast_validate(ExpLog,varargin)

%{
    TEST 0: All codes are four digits
%}
codes = [ExpLog.code];
lessthan4 = find(codes<1000);
morethan4 = find(codes>9999);
if ~isempty(lessthan4) || ~isempty(morethan4)
    success=0;
    fprintf('ERROR: Non-four-digit codes detected:\n');
    % print out codes
    i=0;
    % inv: lessthan4 1..i have been printed
    while i<length(lessthan4)
        i=i+1;
        fprintf('\tExpLog(%d).code = %d\n',lessthan4(i),ExpLog(lessthan4(i)).code);
    end
    k=0;
    % inv: morethan4 1..k have been printed
    while k<length(morethan4)
        k=k+1;
        fprintf('\tExpLog(%d).code = %d\n',lessthan4(i),ExpLog(lessthan4(i)).code);
    end
    return;
end


%{
    TEST 1: Build is at least 2009/02/23
%}
Build = regexp(ExpLog(1).name{1},'(?<=from\s)\d{4}/\d{2}/\d{2}','match');
y = str2double(Build{1}(1:4));
m = str2double(Build{1}(6:7));
d = str2double(Build{1}(9:10));
if y<2009
    success = 0;
    fprintf('ERROR: Game Version too old.\nShould be at least 2009/02/23 but was %s\n',Build{1});
    return;
elseif m<02 || (m==02 && d<23)
    success = 0;
    fprintf('ERROR: Game Version too old.\nShould be at least 2009/02/23 but was %s\n',Build{1});
    return;
end

    
%{
    TEST 2: ExpLog ends with End_of_Log
%}
if ~strncmp(ExpLog(end).name,'End_of_Log',10)
    success = 0;
    disp('Last code in ExpLog is not "End_of_Log"');
    return;
end
    

%{
    TEST 3: EVERY <Minimage>_Start HAS A <Minigame>_End
%}
disp('Validating minigame start and end codes...');
%{
    identify minigame
        0: no minigame selected
        1: MD - Maritime Defender
        2: SJ - StarJack
        3: SJ_SAT - StarJack Sally-Anne Test
        4: SP - Stellar Prospector
        5: AS - Auditory Stimuli
%}
CurrentGame=0; 
MDpass = 0; SJpass = 0;  SJ_SATpass = 0; SPpass = 0; ASpass = 0;
ExpLogIndex=0; %index in ExpLog for minigame validation

% inv: 1..ExpLogIndex in ExpLog have been processed:
%   add 1 to <minigame>pass for each <minigame>_START command
%   subtract 2 from <minigame>pass for each <minigame>_END command
while ExpLogIndex ~= length(ExpLog);
	ExpLogIndex = ExpLogIndex + 1;
    Event = ExpLog(ExpLogIndex);
    switch Event.code
		case 41
			if strncmp(Event.name,'MD_MaritimeDefenderGameBegin', 25)
				CurrentGame=1;
				MDpass = MDpass + 1;
			end	
		case 2
			if strncmp(Event.name,'SJ_START Level', 10)
				CurrentGame=2;
				SJpass = SJpass + 1;
			end
		case 52 %SJ_SAT_START
            if CurrentGame == 2
                SJpass = SJpass - 1;
            end
            if strncmp(Event.name,'SJ_SAT_START',12)
                CurrentGame=3;
                SJ_SATpass = SJ_SATpass + 1;
            end
		case 9 %SP_Phase
			if strncmp(Event.name,'SP_Phase', 8)
				CurrentGame=4;
				SPpass = SPpass + 1;
			end
		case 1 %AS_START
			if strncmp(Event.name,'AS_START', 8)
				CurrentGame=5;
				ASpass = ASpass + 1;
			end
		case 33 %MD_GameSuccess
			if CurrentGame == 1;
				if strncmp(Event.name,'MD_Game', 7)
					MDpass = MDpass - 1;
					CurrentGame=0;
				end
			end
		case 34 %MD_GameFailure
			if CurrentGame == 1;
                %{ 
                  ASSERT: CoherenceEstimate is the command that occurs
                  immediately following the MD_GameSuccess or
                  MD_GameFailure
                %}
                % if CoherenceEstimate command, set game to 0
                if strncmp(UpdatedExpLog(k).name,'DotCoherenceEstimate',20)
                    MDpass = MDpass - 1;
                    CurrentGame=0;
                end
			end
		case 19 %SJ_END_*
			if CurrentGame == 2 || CurrentGame == 3
                if strncmp(Event.name,'SJ_END',5)
                    SJpass = SJpass - 1;
                    CurrentGame=0;
                end
            end
		case 53 %SJ_SAT_END
            if CurrentGame == 3
                if strncmp(Event.name,'SJ_SAT_END', 10)
                    SJ_SATpass = SJ_SATpass - 1;
                    CurrentGame=0;
                end
            end
		case 12 %SP_END
            if CurrentGame == 4
                if strncmp(Event.name,'SP_End', 6)
                    SPpass = SPpass - 1;
                    CurrentGame=0;
                end
            end
		case 6 %AS_END
             if CurrentGame == 5
                if strcmp(Event.name,'AS_END')
                    ASpass = ASpass - 1;
                    CurrentGame=0;
                end
             end
    end
end

% To pass Test 3, it must be the case that:
%   MDpass == SJpass == SJ_SATpass == SPpass == ASpass == 0;

% MD fail
if MDpass~=0 
    success = 0;
    disp('ERROR: number of MD start commands does not equal number of MD end commands');
    return;
end

% SJ fail
if SJpass~=0
    success = 0;
    disp('ERROR: number of SJ start commands does not equal number of SJ end commands');
    return;
end

% SJ_SAT fail
if SJ_SATpass~=0
    success = 0;
    disp('ERROR: number of SJ_SAT start commands does not equal number of SJ_SAT end commands');
    return;
end

% SP fail
if SPpass~=0
    disp('ERROR: number of SP start commands does not equal number of SP end commands');
    success = 0;
    return;
end

% AS fail: return
if ASpass~=0
    disp('ERROR: number of AS start commands does not equal number of AS end commands');
    success = 0;
    return;
end

%{
    TEST 4: Only 'game-valid' events exist
%}

%{
Indices
    a structure that holds the indices of the START commands in ExpLog
        the first cell 'name' contains the name of the minigame
        the second cell 'start' contains the index
%}
if nargin>1
    Indices = varargin{1};
else
    Indices = evalin('base','GameStartIndices');
end
i = 0; % index in Indices

%{ 
Current Game
    0: no game selected
    1: Maritime Defender
    2: StarJack
    3: StellarProspector
    4: Auditory Stimuli
%}
game = 0;

UnknownCodes = 0;

k=0;
%inv: codes 1..k have been checked
% inv: ExpLog[1..k] have been processed
while k ~= length(ExpLog)-1
    k = k + 1;
    code = ExpLog(k).code;
    % test for START command by traversing Indices
    if i<length(Indices) && k==Indices(i+1).start
        i=i+1;
        switch Indices(i).game
            case 'MaritimeDefender'
                game = 1;
            case 'StarJack_Level'
                game = 2;
            case 'StarJack_SallyAnne'
                game = 2;
            case 'StellarProspector'
                game = 3;
            case 'AuditoryStimuli'
                game = 4;
        end
    end
    %if an unknown event (i.e. code 5***), set game to 5
    if code>4999 || code <50001
        game=5;
    end
    if game~=0
        switch game
            case 1
                switch code
                    case 1032 % MD_BossPhaseBegin
                    case 1033 % MD_GameSuccess
                    case 1036 % MD_MENU_INPUT_Left_Click X=??? Y=???
                    case 1041 % MD_MaritimeDefenderGameBegin      
                    case 1007 % MD_ShipIdentifierTestBegin Enemy=Left/Right
                    case 1008 % MD_ShipIdentifierSelectLeft
                    case 1009 % MD_ShipIdentifierSelectRight
                    case 1010 % MD_ShipIdentifierConfirmSelection
                    case 1011 % MD_ShipIdentifierTestEndSuccess
                    case 1012 % MD_ShipIdentifierTestEndFailure
                    case 1013 % MD_ShooterPhaseBegin  
                    case 1014 % MD_ShooterActivateOpenWormholeBeam
                    case 1015 % MD_ShooterCeaseOpenWormholeBeam   
                    case 1016 % MD_ShooterOpenWormholeSuccess
                    case 1017 % MD_ShooterActivateMovePort  
                    case 1018 % MD_ShooterCeaseMovePort
                    case 1019 % MD_ShooterActivateMoveStarboard
                    case 1020 % MD_ShooterCeaseMoveStarboard
                    case 1021 % MD_ShooterPresentFriendly
                    case 1022 % MD_ShooterPresentEnemy
                    case 1023 % MD_ShooterPresentWormhole 
                    case 1024 % MD_ShooterActivateFireWeapon
                    case 1025 % MD_ShooterCeaseFireWeapon  
                    case 1026 % MD_ShooterPlayerWeaponFired
                    case 1028 % MD_ShooterCollectibleSpawned  
                    case 1029 % MD_ShooterPlayerCollectibleCollision Collectible=Weapon/Credits/Carbon
                    case 1030 % MD_ShooterMeteorExplosion
                    case 1031 % MD_ShooterPlayerGetsHit
                    case 1000 % MD_DotCount NumDots=???
                    case 1001 % MD_DotPhaseBegin     
                    case 1002 % MD_DotTrialBegin        
                    case 1003 % MD_DotTrialExpire
                    case 1004 % MD_DotTrialUserRespondLeft
                    case 1005 % MD_DotTrialUserRespondRight 
                    case 1006 % MD_DotCoherenceEstimate Coherence=?.??
                    otherwise
                        fprintf(strcat('ERROR: %d : %s is not a recognized MaritimeDefender code\n',...
                            '  Problem occurred at %d in ExpLog\n'),...
                            code,ExpLog(k).name{1},k);
                        UnknownCodes = UnknownCodes + 1;
                end
            case 2
                switch code
                    case 2000 % SJ_START
                    case 2002 % SJ_START Level=Level1 Room=Room1
                    case 2020 % SJ_END_SUCCESS Level=Levelcase 1
                    case 2052 % SJ_SAT_START
                    case 2053 % SJ_SAT_END
                    case 2058 % SJ_SAT_INPUT_Continue
                    case 2006 % SJ_MENU_INPUT_Right
                    case 2007 % MenuSelectButtonPressed
                    case 2021 % SJ_INPUT_LineOfSight_Toggle
                    case 2023 % SJ_INPUT_Move_Up
                    case 2024 % SJ_INPUT_Move_Down
                    case 2025 % SJ_INPUT_Move_Right
                    case 2026 % SJ_INPUT_Move_Left
                    case 2034 % SJ_INPUT_LeftClick X=??? Y=???
                    case 2038 % SJ_EFT_Stimulus_Presented Key=Key?? Figure=Figure??
                    case 2039 % HIT
                    case 2040 % REJECT
                    case 2041 % FALSE_ALARM        
                    case 2042 % MISS
                    case 2046 % SJ_EFT_INPUT_NoMatch
                    case 2047 % SJ_EFT_INPUT_Match
                    case 2048 % SJ_EFT_INPUT_Proceed
                    case 2049 % SJ_EFT_START
                    case 2050 % SJ_EFT_END_SUCCESS/FAIL
                    case 2055 % SJ_SAT_Video_Stop
                    case 2056
                    case 2059 % SJ_SAT_VideoStart_CargoDrop Planet=RIGHT
                    case 2060 % SJ_SAT_VideoStart_Pirate_Drop Planet=BOTTOM
                    case 2061 % SJ_SAT_VideoStart_Pirate_Theft Planet=RIGHT
                    case 2062 % SJ_SAT_VideoStart_Pirate_NoTheft Planet=BOTTOM
                    case 2064 % SJ_SAT_INPUT_Response_Top
                    case 2065 % SJ_SAT_INPUT_Response_Bottom
                    case 2066 % SJ_SAT_INPUT_Response_Left
                    case 2067 % SJ_SAT_INPUT_Response_Right
                    case 2068 % SJ_SAT_INPUT_NoTheft_Correct/Incorrect***
                    case 2070 % SJ_SAT_FirstOrder_Theft_Correct
                    case 2072 % SJ_SAT_FirstOrder_Theft_IncorrectOtherLocation
                    case 2076 % SJ_SAT_SecondOrder_NoTheft_Correct/Incorrect***
                    case 2078 % SJ_SAT_SecondOrder_Theft_Correct
                    case 2080 % SJ_SAT_SecondOrder_Theft_IncorrectOtherLocation
                    case 2084 % SJ_SAT_FirstOrder_Question_Presented
                    case 2085 % SJ_SAT_VideoStart_Cruiser_NoScan
                    case 2087 % SJ_SAT_VideoStart_Cruiser_View_NoTheft
                    otherwise
                        fprintf(strcat('ERROR: %d : %s is not a recognized StarJack code\n',...
                            '  Problem occurred at %d in ExpLog\n'),...
                            code,ExpLog(k).name{1},k);
                        UnknownCodes = UnknownCodes + 1;
                end
            case 3
                switch code
                    case 3001 % PeripheralStimulusResponsePressed
                    case 3002 % CentralStimulusResponsePressed
                    case 3017 % SP_PeripheralStimulusMissed
                    case 3013 % SP_PeripheralStimulusSpawn Presented
                    case 3014 % SP_CentralStimulusSpawn Presented
                    case 3015 % SP_DistractorSpawn
                    case 3016 % SP_CueChange
                    case 3006 % Unlogged_Event
                    case 3007 % MenuSelectButtonPressed
                    case 3009 % SP_Phase1Begin
                    case 3010 % SP_Phase2Begin
                    case 3011 % SP_Phase3Begin
                    case 3012 % SP_End
                    case 3019 % DistractorDisappear
                    otherwise
                        fprintf(strcat('ERROR: %d : %s is not a recognized Stellar Prospector code\n',...
                            '  Problem occurred at %d in ExpLog\n'),...
                            code,ExpLog(k).name{1},k);
                        UnknownCodes = UnknownCodes + 1;
                end
            case 4
                switch code
                    case 4001 % AS_START
                    case 4002 % AS_TONE_PLAYED Volume=??? Tone=1
                    case 4003 % AS_TONE_PLAYED Volume=??? Tone=2
                    case 4004 % AS_TONE_PLAYED Volume=??? Tone=3
                    case 4005 % AS_TONE_PLAYED Volume=??? Tone=4
                    case 4006
                    otherwise
                        fprintf(strcat('ERROR: %d : %s is not a recognized AuditoryStimuli code\n',...
                            '  Problem occurred at %d in ExpLog\n'),...
                            code,ExpLog(k).name{1},k);
                        UnknownCodes = UnknownCodes + 1;
                end
            case 5 % do nothing
            otherwise
                if code<5000 || code>=6000
                    fprintf('Unrecognized code: %d  - %s found at %d\n',...
                        code,ExpLog(k).name{1},k);
                end
                
        end %endswitch
    end %endif
end %endwhile

if UnknownCodes ~= 0
    success = 0;
    return;
end


%{
    TEST 5: MinigameIndices contains start and end commands
%}
m = 0; % index in MinigameIndices
if nargin>2
    MIndices = varargin{2};
else
    MIndices = evalin('base','MinigameIndices');
end
% inv: MIndices(1..m) contain both start and end values
while m~=length(MIndices)
    m=m+1;
    if isempty(MIndices(m).start) || isempty(MIndices(m).end)
        success = 0;
        fprintf('%s in MinigameIndices does not have both start and end indices',...
            MIndices(m).game);
        return;
    end
end





        
        
% all tests passed
disp('ExperimentLog.txt successfully validated');
success = 1;