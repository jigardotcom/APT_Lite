% TotalLines(): A function that computes the total lines of a file
%
% Usage 
%   >>  nlines = Totallines(filename)
% 
% Output: 
%   nlines - total numbers of line
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

function [nLines] = Totallines(filename)

    fid = fopen(filename,'rt');
    nLines = 0;
    while (fgets(fid) ~= -1),
        nLines = nLines+1;
    end
    fclose(fid);
end
