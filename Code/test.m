a = randi(10,10); % random int mat of 10x10, values from 1-10
b = (a(:,2) ==5)  % indicies of a where columm 2 = 5,
a(b,:)            % print a;