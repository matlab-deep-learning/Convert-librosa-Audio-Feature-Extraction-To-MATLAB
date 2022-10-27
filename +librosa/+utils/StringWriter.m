classdef StringWriter
% STRINGWRITER Local class used to bypass MATLAB code generation when it is
% not requested

%  Copyright 2022 The MathWorks, Inc.

    methods

        function addcr(~,varargin)
            
        end

        function val = char(~)
            val = '';
        end

    end
end