function varargout = stft(X,varargin)
% librosa.stft Short-time Fourier transform.
%
%  This function matches the stft function from Librosa (tested for
%  version 0.10.1). Parameter defaults are identical to the Librosa
%  function.
%
%  S = librosa.stft(X) returns the short-time Fourier transform (stft) of
%  X. 
%
%  S = librosa.stft(X, FFTLength=NFFT) specifies the FFT length. 
%
%  S = librosa.stft(X, Window=WIN) specifies the window used to compute
%  the stft. 
%
%  S = librosa.stft(X, HopLength=H) specifies the hop length.
%
%  S = librosa.stft(X, Center=CENTER) specifies if the signal is
%  centered. If CENTER is true, X is padded as documented by the stft
%  function in the Librosa package.
%
%  S = librosa.stft(X, PaddingMode=MODE) defines the padding mode of the
%  signal. Padding applies when CENTER is true.
%
%  S = librosa.stft(X, GenerateMATLABCode=true) generates and opens an
%  untitled file containing code that implements the code of librosa.stft
%  using the MATLAB function stft.
%
%  librosa.stft(...) with no output arguments plots the magnitude of the
%  stft. This syntax does not support multichannel signals.
%
% % EXAMPLE:
% % Compute and display the stft of a chirp with normalized frequency.
% fs = 4096;
% t = 0:1/fs:2-1/fs;
% x = chirp(t,250,1,500,'q');
% librosa.stft(x)

%  Copyright 2022-2023 The MathWorks, Inc.

%% Validate input signal
validateattributes(X,{'single','double'},...
        {'nonempty','2d'}, ...
        'librosa.stft','y');
if isrow(X)
    X = X.';
end

%% Parse function parameters
p = inputParser;
addRequired(p,'X');

validFFTLength = @(x)isnumeric(x) && isscalar(x) && (x > 0) && floor(x)==x;
addParameter(p,'FFTLength',2048,validFFTLength);

validHopLength =@(x) isnumeric(x) && isscalar(x) && (x > 0) && floor(x)==x;
addParameter(p,'HopLength',512,validHopLength);

validWindowLength =  @(x) isnumeric(x) && isscalar(x) && (x > 0) && floor(x)==x;
addParameter(p,'WindowLength',2048,validWindowLength); 

validWindow = @(x) ischar(x) || isstring(x) || isvector(x) && isreal(x) &&isfloat(x);
addParameter(p,'Window',hann(2048,'periodic'),validWindow); 

validCenter = @(x)isscalar(x) && (isnumeric(x)||islogical(x));
addParameter(p,'Center',true,validCenter); 

validCodegen = @(x)isscalar(x) && (isnumeric(x)||islogical(x));
addParameter(p,'GenerateMATLABCode',false,validCodegen); 

validPad = @(x)ismember(char(x),{'Constant','Edge','Linear ramp','Reflect','Symmetric','Wrap'});
addParameter(p,'PadMode',"Constant",validPad); 

parse(p,X,varargin{:});

FFTLength = p.Results.FFTLength;
center = p.Results.Center;
generateMATLABCode = p.Results.GenerateMATLABCode;

% Reconcile Window and WindowLength specifications, similar to Librosa
% function
if ismember('WindowLength',p.UsingDefaults)
    if ismember('Window',p.UsingDefaults)
        winlen = FFTLength;
    else
        win = p.Results.Window;
        if ischar(win) || isstring(win)
            winlen = FFTLength;
        else
            winlen = numel(win);
        end
    end
else
    winlen = p.Results.WindowLength;
end

if ismember('Window',p.UsingDefaults)
    win = hann(winlen,'periodic');
else        
    win = p.Results.Window;
    if ischar(win) || isstring(win)
        win = sprintf('%s(%d,"periodic")',win,winlen);
        win = eval(win);
    end
end
if (numel(win) ~= winlen)
    error('Window size mismatch')
end

if ismember('HopLength',p.UsingDefaults)
    hopLength = floor(numel(win)/4);
else
    hopLength = p.Results.HopLength;
end

if numel(win)<FFTLength
    L = FFTLength-numel(win);
    L2 = floor(L/2);
    win = win(:);
    win = [zeros(L2,1); win; zeros(FFTLength-L2-numel(win),1)];
end

if generateMATLABCode
    strWriter = StringWriter;
else
    strWriter = librosa.utils.StringWriter;
end

% MATLAB stft does not have a center parameter. Perform the centering here
% to match Librosa.
if center
    padLen = floor(FFTLength/2);
    strWriter.addcr('%s\n%% Pad the signal to center the audio frame.\npadLength = %d;\nnumChannels = size(audioIn,2);','%%',padLen);
    switch p.Results.PadMode
        case {'Constant','Empty'}
            X = [zeros(padLen,size(X,2),'like',X); X; zeros(padLen,size(X,2),'like',X)];

            strWriter.addcr('%s%s\n%% Use constant padding.','%%');
            strWriter.addcr('padBlock = zeros(padLength,numChannels,''like'',audioIn);');
            strWriter.addcr('audioIn = [padBlock; audioIn; padBlock];');
        case 'Edge'
            X = [X(1,:).*ones(padLen,size(X,2),'like',X); X; X(end,:).*ones(padLen,size(X,2),'like',X)];

            strWriter.addcr('%s\n%% Use edge padding.','%%');           
            strWriter.addcr('padBlock1 = audioIn(1,:).*ones(padLength,numChannels,''like'',audioIn);');
            strWriter.addcr('padBlock2 = audioIn(end,:).*ones(padLength,numChannels,''like'',audioIn);');
            strWriter.addcr('audioIn = [padBlock1; audioIn; padBlock2];');
        case 'Linear ramp'
            ramp1 = zeros(padLen,size(X,2),'like',X);
            ramp2 = zeros(padLen,size(X,2),'like',X);
            for index=1:size(X,2)
                p1 = linspace(0,X(1,index),padLen+1);
                p2 = linspace(X(end,index),0,padLen+1);
                ramp1(:,index) = p1(1:end-1);
                ramp2(:,index) = p2(1:end-1);
            end
            X = [ramp1; X; ramp2];

            strWriter.addcr('%s\n%% Use linear ramp padding.','%%');       
            strWriter.addcr('ramp1 = zeros(padLength,numChannels,''like'',audioIn);');
            strWriter.addcr('ramp2 = zeros(padLength,numChannels,''like'',audioIn);');
            strWriter.addcr('for index=1:numChannels\n\tp1 = linspace(0,audioIn(1,index),padLength+1);');
            strWriter.addcr('\tp2 = linspace(0,audioIn(1,index),padLength+1);');
            strWriter.addcr('\tramp1(:,index) = p1(1:end-1);\n\tramp2(:,index) = p2(1:end-1);\nend');
            strWriter.addcr('audioIn = [ramp1; audioIn; ramp2];');
        case 'Reflect'
            pad1 = X(2:padLen+1,:);
            pad2 = X(end-padLen:end-1,:);
            pad1 = pad1(end:-1:1,:);
            pad2 = pad2(end:-1:1,:);
            X = [pad1; X; pad2];

            strWriter.addcr('%s\n%% Use reflection padding.\n','%%');          
            strWriter.addcr('padBlock1 = audioIn(2:padLength+1,:);\n');
            strWriter.addcr('padBlock2 = audioIn(end-padLength:end-1,:);\n');
            strWriter.addcr('padBlock1 = padBlock1(end:-1:1,:);\n');
            strWriter.addcr('padBlock2 = padBlock2(end:-1:1,:);\n');
            strWriter.addcr('audioIn = [padBlock1;audioIn;padBlock2];\n');
        case 'Symmetric'
            pad1 = X(1:padLen,:);
            pad2 = X(end-padLen+1:end,:);
            pad1 = pad1(end:-1:1,:);
            pad2 = pad2(end:-1:1,:);
            X = [pad1; X; pad2];

            strWriter.addcr('%s\n%% Use symmetric padding.','%%');         
            strWriter.addcr('padBlock1 = audioIn(1:padLength,:);');
            strWriter.addcr('padBlock2 = audioIn(end-padLength+1:end,:);');
            strWriter.addcr('padBlock1 = padBlock1(end:-1:1,:);');
            strWriter.addcr('padBlock2 = padBlock2(end:-1:1,:);');
            strWriter.addcr('audioIn = [padBlock1;audioIn;padBlock2];');
        case 'Wrap'
            pad1 = X(end-padLen+1:end,:);
            pad2 = X(1:padLen,:);
            X = [pad1; X; pad2];   

            strWriter.addcr('%s\n%% Use wrap padding.','%%');                
            strWriter.addcr('padBlock1 = audioIn(end-padLength+1:end,:);');
            strWriter.addcr('padBlock2 = audioIn(1:padLength,:);');
            strWriter.addcr('audioIn = [padBlock1;audioIn;padBlock2];');
    end
end

strWriter.addcr('%s\n%% Compute STFT.','%%');
strWriter.addcr('Y = stft(audioIn, Window=%s,...',mat2str(win(:),32));
strWriter.addcr('OverlapLength=%d,...',numel(win)-hopLength);
strWriter.addcr('FFTLength=%d,...',FFTLength);
strWriter.addcr('FrequencyRange="onesided");');

if nargout == 0
    stft(X, Window=win,...
        OverlapLength=numel(win)-hopLength,...
        FFTLength=FFTLength,...
        FrequencyRange="onesided");
else
    varargout{1} = stft(X, Window=win,...
        OverlapLength=numel(win)-hopLength,...
        FFTLength=FFTLength,...
        FrequencyRange="onesided");
    varargout{2} = strWriter.char;
end

if generateMATLABCode
    footer = sprintf('%% _Generated by MATLAB (R) and Audio Toolbox on %s_', string(datetime("now")));
    strWriter.addcr('\n%s\n%s','%%',footer);
    matlab.internal.liveeditor.openAsLiveCode(strWriter.char)
end

end
