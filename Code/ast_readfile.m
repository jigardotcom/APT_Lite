% AST_READFILE() - Read in the log file generated by Astropolis and create a structure 'ExpLog'
% 				based on the data it contains.  After the structure is created, it is validated.
% 
% Usage:
% 		>> ast_readfile
%  else
%       >> ast_readfile(File);
% 
% Input:
%   File    = the full path to an instance of ExperimentLog.txt
% 
% Output:
%   (optional)
%   ExpLog  = structure representing the data in ExperimentLog.txt
%
%   Indices = structure containing the START and END indices for each game
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

function varargout = ast_readfile(varargin)
if nargin<1
    % Get the path to ExperimentLog.txt from the user
    FileName = input('Please enter the path to ExperimentLog.txt \ne.g. ~/Public/autismArchive/Subjects/1/ExperimentLog.txt\n','s');
else
    FileName = varargin{1};
end
    
% Put the information from the file in FileName into the structure ExpLog
[ExpLog SuccessfulRead GameStartIndices MinigameIndices] = ast_makestructure(FileName);

% If MakeStructure was successful, validate ExpLog
if SuccessfulRead
    ast_validate(ExpLog,GameStartIndices,MinigameIndices);
end

% if the call asked for any return values, return them
if nargout>0
    varargout{1}=ExpLog;
    if nargout>1
        varargout{2}=MinigameIndices;
    end
else
    % otherwise store returned values in base workspace
    assignin('base','ExpLog',ExpLog);
    assignin('base','SuccessfulRead',SuccessfulRead);
    assignin('base','GameStartIndices',GameStartIndices);
    assignin('base','MinigameIndices',MinigameIndices);
end



