% APT_Lite() - create the GUI for the astropolis processing toolkit - Lite(APT - Lite)
%
% 
% This programm creates the GUI for the astropolis processing toolkit - Lite, 
% whose basic function is to load behavioural data from EXPLOG file 
% generated from the Astropolis game and process it. Processing includes
% steps such as aligning and updating events in EEG dataset (if the data
% are from a Lab file) based on the events in EXPLOG file.
%
% The GUI also enables generation of results from the beahviural data that 
% can be exported to text or .csv files. If EEG data are available (for Lab 
% data sets), updated EEG dataset is generated as a new file which is 
% compatible to use with EEGLAB and can be used for further EEG analysis.

% Author: Jigar Patel
% 2011 University of Hyderabad, India
 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 
% Version 1.0
%---------------------
% Date: 2011/09/14 - Hyderabad, India



function APT_Lite
evalin('base','clear all') % clears all variables from base workspace (to aviod computations on residual data)
astro_mainfig;
% define menus
% ------------
W_MAIN = findobj('tag','Astropolis Processing Toolkit - Lite');
set(W_MAIN,'MenuBar','none');

% create File menu
m_File = uimenu('Label','File');
    uimenu(m_File,'Label','Load video game log file','Callback',@readexplog);
    uimenu(m_File,'Label','Load video game log file (laptop)','Callback',@readlaptoplog);
    uimenu(m_File,'Label','Load EEG dataset file','Callback',@findset,'Separator','on');
    uimenu(m_File,'Label','Quit','Callback',@quitapt,'Separator','on');
% create Process menu
m_Process = uimenu('Label','Process');
    uimenu(m_Process,'Label','Process Lab Dataset','Callback',@process);
    uimenu(m_Process,'Label','Align and Update EEG Dataset','Callback',@align,'Separator','on');
    
% create Data menu
m_Data = uimenu('Label','Data');
    uimenu(m_Data,'Label','Process & Export MD Results to .csv (Except Motor Potential)','Callback',@behdata_MD);
    uimenu(m_Data,'Label','Process & Export MD Motor Potential Results to .csv','Callback',@behdata_MD_Motor);
    uimenu(m_Data,'Label','Process & Export SP Results to .csv','Callback',@behdata_SP);
    uimenu(m_Data,'Label','Process & Export SJ Results to .csv','Callback',@behdata_SJ);
    %uimenu(m_Data,'Label','Show behavioural summary results','Callback',@behdata,'Separator','on');  
    %uimenu(m_Data,'Label','Show behavioural summary results (laptop)','Callback',@behdata_laptop);
    

end

%%%%%%%%%%%%%%%%%%
% Create the GUI %
% -------------- %
%%%%%%%%%%%%%%%%%%
function astro_mainfig
% Further modified from Astropolis.m
% modified from eeglab.m - Arnaud Delorme, CNL / Salk Institute, 2001

    BGCOLOR = [0.1 0.1 0.1];
    COLOR = [0.976 0.969 0.969];
    FONT = 'Courier';
    WINMINX = 17;
    WINMAXX = 250;
    WINVDEC = 13;
    NBLINES = 8;
    WINV    = WINVDEC*NBLINES;

    BORDERINT = 4;
    BORDEREXT = 10;

    ah = findobj('tag','Astropolis Processing Toolkit - Lite');
    if ~isempty(ah)
        disp('Astropolis Processing Toolkit is already running, closing previous instance...');
        close(ah);
    end;

    W_MAIN = figure('Units','points',...
        'PaperPosition',[18 180 576 500],...
        'PaperUnits','points',...
        'name', 'Astropolis Processing Toolkit - Lite',...
        'numbertitle','off',...
        'resize','off',...
        'Position',[300 200 (WINMINX+WINMAXX+2*BORDERINT+2*BORDEREXT) (WINV+2*BORDERINT+2*BORDEREXT)],...
        'color',BGCOLOR,...
        'Tag','Astropolis Processing Toolkit - Lite',...
        'visible','off');
    try
        set(W_MAIN,'UserData',[],'NextPlot','new');
    catch
    end;


    set(gcf,'Position',[200 400 (WINMINX+WINMAXX+2*BORDERINT+2*BORDEREXT) (WINV+2*BORDERINT+2*BORDEREXT)]);
    set(W_MAIN,'UserData',[],'visible','on');
    return;

end

% FILE commands
% -------------

%Load EEG Dataset 
function findset(varargin)
    % Prompt User for the EEG dataset file and Load it into Memory.
    [fname fpath] = uigetfile('/*.set','Select a set to add');
    
    % make full path relative to subjects folder
    fullpath = strcat(fpath,fname);
    
    EEG = pop_loadset(fullpath); % EEGLAB function to Load Datasets.
    
    assignin('base','EEG',EEG);  % Asigning EEG Variable into base workspace.

    % Catch user cancel operation
end

% Quit APT
function quitapt(varargin)
    close(gcf); % closes GUI
    
    clear all; % Clears Workspace.
end
 


% Load an ExperimentLog.txt file

function readexplog(varargin)

    % let prompt user to select an Experiment Log
    [fname fpath fi] = uigetfile('/*.txt','Select ExperimentLog.txt');
    
    % make full path relative to subjects folder
    fullpath = strcat(fpath,fname);

    [ExpLog Indices] = ast_readfile(fullpath);

    % store EXPLOG and MinigameIndices on the base workspace (for Process functions)
    assignin('base','ExpLog',ExpLog);
    assignin('base','MinigameIndices',Indices);
    sprintf('The ExperimentLog (Lab) has been loaded successfully')
    msgbox('The ExperimentLog (Lab) has been loaded successfully');

end

% Load an ExperimentLog.txt file generated by a laptop (no EEG)
function readlaptoplog(varargin)

    % let prompt user to select an Experiment Log
    [fname fpath fi] = uigetfile('/*.txt','Select ExperimentLog.txt');
    
    % make full path relative to subjects folder
    fullpath = strcat(fpath,fname);
    
    [ExpLog Indices] = ast_readfile(fullpath);

    % store EXPLOG on the base workspace (for Process functions)
    assignin('base','ExpLog_Laptop',ExpLog);
    assignin('base','MinigameIndices_Laptop',Indices);
    sprintf('The ExperimentLog (Laptop) has been loaded successfully')

end


% PROCESS commands
% -------------

% Process the EXPLOG file, calculate results of behavioural data as well as 
% generate new structure based on EXPLOG structure that contains the 
% updated event codes based on epochs (See Matthew's Wiki page)
%
% NOTE: The function of updating EEG dataset is not used from ast_process
% as there is a separate module now developed for this purpose in APT_Lite, 
% called, sessionAlign.

function process(varargin)
 
    % Determining whether user has loaded Behavioural Log before processing,
    % if not, display a message.
 
    try
        ExpLog = evalin('base','ExpLog');
    catch Err
        if(strcmp(Err.identifier,'MATLAB:UndefinedFunction'))
            msgbox('Behavioural Log is not Loaded, Please load it before processing! ','Error');
        end
        return;
    end

    % processes the dataset based on the specifications in Wiki, storing the
    % resulting values in the appropriate structures. In APT_Lite, only
    % UpdatedExpLog structure is taken for further processing. The
    % remaining structures returned by AST_PROCESS such as MDBehData,
    % SJBehData, SPBehData, and FOBEhData are discarded. The result
    % processing is now done in MD_COMPILE, SJ_COMPILE and SP_COMPIE
    % functons.

    [UpdatedExpLog MDBehData SJBehData SPBehData FOBehData] = ast_process(ExpLog,'EEG',0);

    % store the structures UpdatedExpLog in the base workspace.

    assignin('base','UpdatedExpLog',UpdatedExpLog);
    
    sprintf('The ExperimentLog (Lab) has been processed successfully')
    
end

% Process the EXPLOG file generated from Laptop, calculate results of 
% behavioural data as well as generate new structure based on EXPLOG 
% structure that contains the updated event codes based on epochs 
% (See Matthew's Wiki page)
%

%{
function process_laptop(varargin)

    % Determining whether user has loaded Behavioural Log before processing,
    % if not, display a message.


    try
        ExpLog_Laptop = evalin('base','ExpLog_Laptop');
    catch Err
        if(strcmp(Err.identifier,'MATLAB:UndefinedFunction'))
            msgbox('Behavioural Log is not Loaded, Please load it before processing! ','Error');
        end
        return;        
    end
    
    % processes the dataset based on user specifications, storing the
    % resulting values in the appropriate structures
    
    [UpdatedExpLog MDBehData SJBehData SPBehData FOBehData] = ast_process(ExpLog_Laptop,'EEG',0);

    % store the structures UpdatedExpLog, MDBehData, SJBehData, SPBehData,
    % FOBehData in the base workspace.

    assignin('base','UpdatedExpLog_Laptop',UpdatedExpLog);
    assignin('base','MDBehData_Laptop',MDBehData);
    assignin('base','SJBehData_Laptop',SJBehData);
    assignin('base','SPBehData_Laptop',SPBehData);
    assignin('base','FOBehData_Laptop',FOBehData);
    
    sprintf('The ExperimentLog (Laptop) has been processed successfully')
end

%}

% Align the EEG events to the behavioural Log file and then create a new
% EEG dataset containing new events.
function align(varargin)

    % Determining wether User had Loaded and processed Behavioural Log as
    % well as loaded EEG dataset file
    % if not, display a message.
    try
        ExpLog = evalin('base','ExpLog');
        UpdatedExpLog = evalin('base','UpdatedExpLog');
        EEG = evalin('base','EEG');

    catch Err
        if(strfind(Err.message, 'UpdatedExpLog'))
            msgbox('Behavioural Log is not Processed! ','Error');
        else if (strfind(Err.message, 'ExpLog'))
                msgbox('Behavioural Log is not Loaded! ','Error');
            else if (strfind(Err.message, 'EEG'))
                    msgbox('EEG Dataset is Not Loaded! ','Error');
                end
            end
        end
        return;
    end

    fprintf('\nAlignment and updating of EEG dataset based on Behavioural Log file has begun');

    % A module to align EEG dataset events to the Behavioural Log file and
    % calculate the latency offset for each session of the log file.

    [AlignedLatency AlignedEvent TemporalError T_Delta mark Log_SuccDelta Log_EEG_Delta] = AlignAndOffsetCalc(ExpLog,UpdatedExpLog, EEG.event);

    % construct new EEG events structure based on the behavioural log and
    % calculate the offsets for each session. The events in the EEG dataset 
    % will be replaced completely by the events in updated behavioural log 
    % structure (generated from the ast_process function and contains new 
    % event codes)

    events = MakeEventsV2(AlignedLatency,AlignedEvent);
    %events = MakeEventsV3(UpdatedExpLog, TemporalError, T_Delta);
    fprintf('\nAlignment and updating of EEG dataset based on Behavioural Log file has Finished');
    EEG.event = events;

    % prompt user to save the new EEG dataset.

    Question = 'Where would you like to save Updated EEG Files ?';
    response = questdlg(Question);
    % if user selects 'No' or 'Cancel', return
    if strcmp(response,'No') || strcmp(response,'Cancel')
        return;
    else
        [fname, fpath] = uiputfile('/.set','Save as');

        pop_saveset(EEG,'filename',fname,'filepath',fpath);

    end
    
end



% DATA commands
% -------------

% prints behavioural data in the command window as well as prompts user to
% export the same as a text file.

function behdata(varargin)

    % Determining whether user has processed Behavioural Log before calling
    % this function
    % if not, display a message.
    
    try

        MDBehData = evalin('base','MDBehData');
        SJBehData = evalin('base','SJBehData');
        SPBehData = evalin('base','SPBehData');

    catch Err
        
        if(strcmp(Err.identifier,'MATLAB:UndefinedFunction'))
            msgbox('Error! Minigames needs to be processed before summary results can be generated! ','Error');
        end
        return;
    end


    % Fetching behavioural results from the structures generated from
    % the ast_process function

    MD = sprintf(strcat('GAcc =\t',num2str(MDBehData.GAcc),'\nGLat\tMean =\t',...
        num2str(MDBehData.GLat.Mean),'\tVariance =\t',num2str(MDBehData.GLat.Variance),...
        '\nNGAcc =\t',num2str(MDBehData.NGAcc),'\nNGLat\tMean =\t',...
        num2str(MDBehData.NGLat.Mean),'\tVariance =\t',num2str(MDBehData.NGLat.Variance),...
        '\nDotCoh =',num2str(MDBehData.DotCoh)));
    
    SP = sprintf(strcat('PAccC =\t',num2str(SPBehData.PAccC),'\nPLatC:\tMean =\t',...
        num2str(SPBehData.PLatC.Mean),'\tVariance =\t',num2str(SPBehData.PLatC.Variance),...
        '\nPAccN =\t',num2str(SPBehData.PAccN),'\nPLatN:\tMean =\t',...
        num2str(SPBehData.PLatN.Mean),'\tVariance =\t',num2str(SPBehData.PLatN.Variance),...
        '\nCAcc =\t',num2str(SPBehData.CAcc),'\nCLat:\tMean =\t',...
        num2str(SPBehData.CLat.Mean),'\tVariance =\t',num2str(SPBehData.CLat.Varience)));
    
    SJ = sprintf(strcat('Dprime = ',num2str(SJBehData.DPrime),'\nEFTAcc =',...
        num2str(SJBehData.EFTAcc),'\nEFTLat:\tMean =\t',num2str(SJBehData.EFTLat.Mean),...
        '\tVariance =\t',num2str(SJBehData.EFTLat.Variance)));
    
    Results = sprintf(strcat(MD,'\n',SJ,'\n',SP));
    
    message = strcat(...
        '\n\n\nGAcc = Maritime Defender Go Accuracy\n',...
        'GLat = Maritime Defender Go Response Latency\n',...
        'NGAcc = Maritime Defender NoGo Accuracy\n',...
        'NGLat = Maritime Defender NoGo Response Latency\n',...
        'DotCoh = Maritime Defender Dot-Motion Coherence Threshold\n',...
        'DPrime = StarJack EFT d'' Statistic\n',...
        'EFTAcc = StarJack EFT Accuracy\n',...
        'EFTLat = StarJack EFT Response Latency\n',...
        'PAccC = Stellar Prospector Peripheral Accuracy for Cued Targets\n',...
        'PLatC = Stellar Prospector Peripheral Response Latency for Cued Targets\n',...
        'PAccN = Stellar Prospector Peripheral Accuracy for Non-Cued Targets\n',...
        'PLatN = Stellar Prospector Peripheral Response Latency for Non-Cued Targets\n',...
        'CAcc = Stellar Prospector Accuracy for Central Stimuli\n',...
        'CLat = Stellar Prospector Response Latency for Central Stimuli\n');
    
    % Printing results in the Command Window
    sprintf(strcat(Results,message))
    %sprintf(message)
 
    % Prompts the user whether to export the results into a text file.
    % if yes, prompt a filename and location and then create the results file.

    Question = 'Would you like to export Behavioural results to a text file?';
    response = questdlg(Question);
    
    % if user selects 'No' or 'Cancel', return
    if strcmp(response,'No') || strcmp(response,'Cancel')
        return;
    else
        [fname, fpath] = uiputfile('/.txt','Save as');

        fullpath = strcat(fpath,fname);
        Output = fopen(fullpath,'w');
        fprintf(Output,Results);
        fprintf(Output,message);
        fclose(Output);

        SavedMessage = 'Behavioural Results Saved. \n';
        sprintf(SavedMessage)
    end

    msgbox(Results);
end

% prints behavioural  data from laptop Log in the command window as well as
% prompts user to export the same as a text file.

function behdata_laptop(varargin)
 
   % Determining whether user has processed Behavioural Log before calling
   % this fucntion
   % if not, display a message.

    try
        MDBehData = evalin('base','MDBehData_Laptop');
        SJBehData = evalin('base','SJBehData_Laptop');
        SPBehData = evalin('base','SPBehData_Laptop');
    catch Err
        if(strcmp(Err.identifier,'MATLAB:UndefinedFunction'))
            msgbox('Error! Minigames needs to be processed before summary results can be generated! ','Error');
        end
        return;
    end
    
    % Fetching behavioural results from structures generated from the 
    % ast_process function
    
    MD = sprintf(strcat('GAcc =\t',num2str(MDBehData.GAcc),'\nGLat\tMean =\t',...
        num2str(MDBehData.GLat.Mean),'\tVariance =\t',num2str(MDBehData.GLat.Variance),...
        '\nNGAcc =\t',num2str(MDBehData.NGAcc),'\nNGLat\tMean =\t',...
        num2str(MDBehData.NGLat.Mean),'\tVariance =\t',num2str(MDBehData.NGLat.Variance),...
        '\nDotCoh =',num2str(MDBehData.DotCoh)));
    
    SP = sprintf(strcat('PAccC =\t',num2str(SPBehData.PAccC),'\nPLatC:\tMean =\t',...
        num2str(SPBehData.PLatC.Mean),'\tVariance =\t',num2str(SPBehData.PLatC.Variance),...
        '\nPAccN =\t',num2str(SPBehData.PAccN),'\nPLatN:\tMean =\t',...
        num2str(SPBehData.PLatN.Mean),'\tVariance =\t',num2str(SPBehData.PLatN.Variance),...
        '\nCAcc =\t',num2str(SPBehData.CAcc),'\nCLat:\tMean =\t',...
        num2str(SPBehData.CLat.Mean),'\tVariance =\t',num2str(SPBehData.CLat.Varience)));
    
    SJ = sprintf(strcat('Dprime = ',num2str(SJBehData.DPrime),'\nEFTAcc =',...
        num2str(SJBehData.EFTAcc),'\nEFTLat:\tMean =\t',num2str(SJBehData.EFTLat.Mean),...
        '\tVariance =\t',num2str(SJBehData.EFTLat.Variance)));
    
    Results = sprintf(strcat(MD,'\n',SJ,'\n',SP));
    
    message = strcat(...
        '\n\n\nGAcc = Maritime Defender Go Accuracy\n',...
        'GLat = Maritime Defender Go Response Latency\n',...
        'NGAcc = Maritime Defender NoGo Accuracy\n',...
        'NGLat = Maritime Defender NoGo Response Latency\n',...
        'DotCoh = Maritime Defender Dot-Motion Coherence Threshold\n',...
        'DPrime = StarJack EFT d'' Statistic\n',...
        'EFTAcc = StarJack EFT Accuracy\n',...
        'EFTLat = StarJack EFT Response Latency\n',...
        'PAccC = Stellar Prospector Peripheral Accuracy for Cued Targets\n',...
        'PLatC = Stellar Prospector Peripheral Response Latency for Cued Targets\n',...
        'PAccN = Stellar Prospector Peripheral Accuracy for Non-Cued Targets\n',...
        'PLatN = Stellar Prospector Peripheral Response Latency for Non-Cued Targets\n',...
        'CAcc = Stellar Prospector Accuracy for Central Stimuli\n',...
        'CLat = Stellar Prospector Response Latency for Central Stimuli\n');
    

    
    % Printing results in the Command Window
    sprintf(Results)
    sprintf(message)
 
    % Prompts the user whether to export the results into a text file.
    % if yes, prompt a filename and location and then create the results file.

    Question = 'Would you like to export Behavioural results to a text file?';
    response = questdlg(Question);
    
    % if user selects 'No' or 'Cancel', return
    if strcmp(response,'No') || strcmp(response,'Cancel')
        return;
    else
        [fname, fpath] = uiputfile('/.txt','Save as');

        fullpath = strcat(fpath,fname);
        Output = fopen(fullpath,'w');
        fprintf(Output,Results);
        fprintf(Output,message);
        fclose(Output);

        %SavedMessage = strcat('Saved Behavioural Results at:-',fpath,'\',fname ,'\n');
        SavedMessage = 'Behavioural Results Saved. \n';
        sprintf(SavedMessage)
    end

     msgbox(Results);
end

function behdata_MD(varargin)
 
   % Determining whether user has processed Behavioural Log before calling
   % this fucntion
   % if not, display a message.

   try
       % Ask the user to specify which log (ExpLog/ExpLog_laptop) to process
       qstr = 'Which log file would you like to process?';
       response = questdlg(qstr,'Select an ExperimentLog.txt','Laptop log',...
           'Lab log','Lab log');
       switch response
           case 'Laptop log'
               
               ExpLogStructure= evalin('base','ExpLog_Laptop');
               MinigameIndices = evalin('base','MinigameIndices_Laptop');
               
               [fname, fpath] = uiputfile('/.csv','Save as');
               
               if (fname)                   
                   filepath = strcat(fpath,fname);
                   [MDBehData Result] = MD_Compile(ExpLogStructure,MinigameIndices,filepath);
                   assignin('base','MDBehData_Laptop',MDBehData);
                   msgbox(Result);
               end
               
           case 'Lab log'
               
               ExpLogStructure= evalin('base','ExpLog');
               MinigameIndices = evalin('base','MinigameIndices');
               
               [fname, fpath] = uiputfile('/.csv','Save as');
               
               if (fname)                   
                   filepath = strcat(fpath,fname);
                   [MDBehData Result] = MD_Compile(ExpLogStructure,MinigameIndices,filepath);
                   assignin('base','MDBehData',MDBehData);
                   msgbox(Result);
               end
               
           otherwise
               return
       end
       
   catch Err
       if(strcmp(Err.identifier,'MATLAB:UndefinedFunction'))
           msgbox('Behavioural Log is not Loaded, Please load it before processing! ','Error');
       else
           msgbox('Unknown Error','Error');
            fprintf(Err.identifier)
       end
       return;
   end
   
   
end

function behdata_MD_Motor(varargin)
 
   % Determining whether user has processed Behavioural Log before calling
   % this fucntion
   % if not, display a message.
   
   try
 
       % Ask the user to specify which log (ExpLog/ExpLog_laptop) to process
       qstr = 'Which log file would you like to process?';
       response = questdlg(qstr,'Select an ExperimentLog.txt','Laptop log',...
           'Lab log','Lab log');
       switch response
           case 'Laptop log'
               
               ExpLogStructure= evalin('base','ExpLog_Laptop');
               MinigameIndices = evalin('base','MinigameIndices_Laptop');
               
               [fname, fpath] = uiputfile('/.csv','Save as');
               
               if (fname)
                   filepath = strcat(fpath,fname);
                   Result =  MD_motor_pot(ExpLogStructure,MinigameIndices,filepath);
                   msgbox(Result);
               end
           case 'Lab log'
               
               ExpLogStructure= evalin('base','ExpLog');
               MinigameIndices = evalin('base','MinigameIndices');
               
               [fname, fpath] = uiputfile('/.csv','Save as');
               
               if (fname)
                   filepath = strcat(fpath,fname);
                   Result =  MD_motor_pot(ExpLogStructure,MinigameIndices,filepath);
                   msgbox(Result);
               end
           otherwise
               return
       end
       
   catch Err
       if(strcmp(Err.identifier,'MATLAB:UndefinedFunction'))
           msgbox('Behavioural Log is not Loaded, Please load it before processing! ','Error');
       else
           msgbox('Unknown Error','Error');
           fprintf(Err.identifier)
       end
       return;
   end

end

function behdata_SP(varargin)

% Determining whether user has processed Behavioural Log before calling
% this fucntion
% if not, display a message.

try
    % Ask the user to specify which log (ExpLog/ExpLog_laptop) to process
    qstr = 'Which log file would you like to process?';
    response = questdlg(qstr,'Select an ExperimentLog.txt','Laptop log',...
        'Lab log','Lab log');
    switch response
        case 'Laptop log'
            
            ExpLogStructure= evalin('base','ExpLog_Laptop');
            MinigameIndices = evalin('base','MinigameIndices_Laptop');
            
            [fname, fpath] = uiputfile('/.csv','Save as');
            
            if (fname)
                filepath = strcat(fpath,fname);
                [SPBehData Result] = SP_Compile(ExpLogStructure,MinigameIndices,filepath);
                assignin('base','SPBehData_Laptop',SPBehData);
                
                msgbox(Result);
            end
            
        case 'Lab log'
            
            ExpLogStructure= evalin('base','ExpLog');
            MinigameIndices = evalin('base','MinigameIndices');
            
            [fname, fpath] = uiputfile('/.csv','Save as');
            
            if (fname)
                filepath = strcat(fpath,fname);
                [SPBehData Result] = SP_Compile(ExpLogStructure,MinigameIndices,filepath);
                assignin('base','SPBehData',SPBehData);
                msgbox(Result);
            end
            
        otherwise
            return
    end
    
catch Err
    if(strcmp(Err.identifier,'MATLAB:UndefinedFunction'))
        msgbox('Behavioural Log is not Loaded, Please load it before processing! ','Error');
    else
        msgbox(Err.identifier,'Error');
        
    end
    return;
end


end

function behdata_SJ(varargin)

% Determining whether user has processed Behavioural Log before calling
% this function
% if not, display a message.

try
    % Ask the user to specify which log (ExpLog/ExpLog_laptop) to process
    qstr = 'Which log file would you like to process?';
    response = questdlg(qstr,'Select an ExperimentLog.txt','Laptop log',...
        'Lab log','Lab log');
    switch response
        case 'Laptop log'
            
            ExpLogStructure= evalin('base','ExpLog_Laptop');
            MinigameIndices = evalin('base','MinigameIndices_Laptop');
            
            [fname, fpath] = uiputfile('/.csv','Save as');
            
            if (fname)
                filepath = strcat(fpath,fname);
                [SJBehData Result] = SJ_Compile(ExpLogStructure,MinigameIndices,filepath);
                assignin('base','SJBehData_Laptop',SJBehData);
                
                msgbox(Result);
            end
            
        case 'Lab log'
            
            ExpLogStructure= evalin('base','ExpLog');
            MinigameIndices = evalin('base','MinigameIndices');
            
            [fname, fpath] = uiputfile('/.csv','Save as');
            
            if (fname)
                filepath = strcat(fpath,fname);
                [SJBehData Result] = SJ_Compile(ExpLogStructure,MinigameIndices,filepath);
                assignin('base','SJBehData',SJBehData);
                msgbox(Result);
            end
            
        otherwise
            return
    end
    
catch Err
    if(strcmp(Err.identifier,'MATLAB:UndefinedFunction'))
        msgbox('Behavioural Log is not Loaded, Please load it before processing! ','Error');
    else
        msgbox(Err.identifier,'Error');
    end
    return;
end

end
