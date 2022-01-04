% MD_MOTOR_POT() - Compile behavioural results related to the Motor
%                  Preparatory Potentials of the minigame Maritime Defender 
%
% This function takes the internal ExpLogStructure and the MinigameIndices
% generated by ast_makestructure.m and gives the behavioural outputs for
% Maritime Defender minigame for the specified subject in one comma
% separated file (.csv file). The results generated here will enable
% plotting wormhole events versus the number of movement commands,
% indicating any improvement in the player's motor performance over time.  
%                                                    
% USAGE:                                 
% >> Output = MD_motor_pot(ExpLogStructure,MinigameIndices,filepath)
%
% INPUT:
% 
%   ExpLogStructure: generated from ast_makestructure.m containing four
%                    structures - code (four digit event code), time (time of the event),
%                    mark (tick mark), and name (the event string reported).
%   
%   MinigameIndices: For each minigame session it records in its structure
%                    the name of the minigame, start and end of the minigame (the line
%                    numbers in the corresponding ExpLogStructure file)
%                                                                 
%   filepath: the file path obtained from user for saving the .csv result file 
%
% OUTPUT: 
% First part of the csv file has the following headers
%  Wormhole_Event, Total_Movement, Elapsed_Time, Anscombe_Transform
%    Wormhole_Event: Event where player shoots at the wormwhole for it to
%                    open.
%    Total_Movement: Number of distinct movement commands
%                   (MD_ShooterActivateMovePort (1017) or
%                    MD_ShooterActivateMoveStarboard (1019)) 
%                    between each pair of MD_ShooterPresentWormhole (1023)
%                    and MD_ShooterOpenWormholeSuccess (1016)
%    Elapsed_Time(s): Elapsed time between each pair of
%                     MD_ShooterPresentWormhole (1023) and 
%                     MD_ShooterOpenWormholeSuccess (1016)
%    Anscombe_Transform: Total_Movement value after applying Anscombe Transform 
%
% The Second part of the csv file gives mean and std of Elapsed Times and
% distinct movement commands after Anscombe transformation
%
% PRECONDITION: ExpLogStructure considered here is the one that is 
%               generated by ast_makestructure.m BUT NOT already processed
%               by ast_process.m
%
% see also: APT_Lite.m
 

% Changelog 26-May-2012 ( Jigar Patel)
% - Elapsed time and Anscombe transformation of movement commands are now
%   stored in an array.
% - Mean and STD of Elapsed time and Anscombe transformation of movement
%   commands are now calculated.


% Author: Rakesh Sengupta (RS)
% 2011 University of Hyderabad
 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
 
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307,
% USA.

function Output = MD_motor_pot(ExpLogStructure,MinigameIndices,filepath)




ExpLog = ExpLogStructure;      % ExpLog is a structure containing the log data. The structure has four elements i.e. EventTime, EventMark, EventCode, EventName


Res = fopen(filepath,'w');     % Creates the Result file

fprintf(Res,'Wormhole_Event,Total_Movement,Elapsed_Time(s),Anscombe_Transform \n');     % Prints the Headings into Result File
Flag = 0 ;              % Flag which will indicates whether an event occured or not
MD_movement=0;
Count = 1;

Elapsed_time=0;
Total_MD_movement=0;
Wormhole_Event=0;

% From each minigame session get the Maritime Defender minigames on which
% to run the behavioural analysis for their start and end points defined by
% istart and iend which define in which line of ExpLog this particular
% minigame session started and ended.


for j=1:size(MinigameIndices,2)
    if(  strcmp(MinigameIndices(1,j).game,'MaritimeDefender')==1)
    istart=MinigameIndices(1,j).start;
    iend=MinigameIndices(1,j).end;
    
for i=istart:iend                  % Loop over the particular minigame session
    if( ExpLog(1,i).code == 1016 ) % Look for the wormwhole opening event
        Lat = ExpLog(1,i).time;
        K=i;
        
        while i>istart && ~(ExpLog(1,i).code== 1023) % Look for the player shooting to open the wormwhole
            i=i-1;
            % 3017 = MD_ShooterActivateMovePort
            % 3019 = MD_ShooterActivateMoveStarboard
            
            if( ExpLog(1,i).code == 1019 || ExpLog(1,i).code ==1017) % Look for movement commands
                MD_movement=MD_movement+1;
            end
        end
        Elapsed_time(Count) = ExpLog(1,K).time-ExpLog(1,i).time; % 
       
        
        Wormhole_Event=Wormhole_Event+1; % Get the index of wormwhole event
        
        Total_MD_movement=MD_movement;   % Calculate Total Number of movement commands
      
        anscombe(Count)=2*sqrt(Total_MD_movement+(3/8)); % Calculate the anscombe transform of the number of movemnent commands
        Count = Count +1;
        MD_movement=0;
        Flag = 1;
    end
    
        if(Flag ==1)
            fwrite(Res,num2str(Wormhole_Event));
            fprintf(Res,',');
            fwrite(Res,num2str(Total_MD_movement));
            fprintf(Res,',');
            fwrite(Res,num2str(Elapsed_time(Count-1)));
            fprintf(Res,',');
            fwrite(Res,num2str(anscombe(Count-1)));
            fprintf(Res,'\n');
            Flag=0;
        end
end
    end
end

Mean_RT = mean(Elapsed_time);
Std_RT = std(Elapsed_time);

Mean_Movement = mean(anscombe);
Std_Movement = std(anscombe);

fprintf(Res,'\nMean Elapsed time:,');                % Prints the no. of succeeded Dot trials
fwrite(Res,num2str(Mean_RT));
fprintf(Res,'\n');
fprintf(Res,'SD Elapsed time:,');                     % Prints the no. of failed Dot trials
fwrite(Res,num2str(Std_RT));

fprintf(Res,'\nMean of distinct movement commands after Anscombe transformation:,');                % Prints the no. of succeeded Dot trials
fwrite(Res,num2str(Mean_Movement));
fprintf(Res,'\n');
fprintf(Res,'SD of distinct movement commands after Anscombe transformation:,');                     % Prints the no. of failed Dot trials
fwrite(Res,num2str(Std_Movement));


X = fclose(Res);
Output = strcat('The Results of MD minigame(Motor Potential) have been saved at: ',filepath);        % Print a text to show that the program got executed successfully
