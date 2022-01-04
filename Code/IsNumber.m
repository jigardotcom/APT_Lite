% ISNUMBER() - is a function to check whether the input parameter is a number
% or not. 
%
% Usage:[Return]  = IsNumber(Input)
%   Where Input is the variable that needs to be verified
%
% OUTPUT : if variable is number it will return the value of that variable
% in string format, if not it will return string 'Not Applicable'
%
% This function is used to display meaningful output for variables that
% end up as NaN in Matlab

% Author : Jigar Patel
% 2012 University of Hyderabad
 
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


function [Return]  = IsNumber(Input)
if(isnan(Input))
    Return =  'Not Applicable';
else
    Return = num2str(Input);
end
end