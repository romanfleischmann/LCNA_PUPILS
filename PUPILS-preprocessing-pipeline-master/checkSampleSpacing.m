function [out] = checkSampleSpacing(dataframe)
% This function checks that there is no missing data points in the input
% data. In case of missing data points it returns a 0, otherwise  the
% function ends returning a 1.

 checksum = sum(abs(diff(diff(dataframe(:, 1)))));
  if checksum == 0
      out = 1; % Samples are equally spaced
  else
      out = 0;  % Samples are not equally spaced (missing data)
  end
 
end