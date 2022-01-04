% AST_GETDURATION() - given the indices of two events, AST_GETDURATION 
%                   extracts their duration
% 					Note: input order is irrelevant
%
% Usage:
% 	>> Duration = ast_getduration(i1,i2)
%
% Inputs:
% 	i1 	(double) the index in ExpLog of the first event
%
% 	i2	(double) the index in ExpLog of the second event
%
% Output:
% 	Duration 	(double) the time (sec) between the two events
%
% Precondition: i1 and i2 are < 0 and less than length(ExpLog)
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
% Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307,
% USA.

function Duration = ast_getduration(i1, i2)

global EXPLOG

Time1 = EXPLOG(i1).time;
Time2 = EXPLOG(i2).time;
Duration = abs(Time2 - Time1);