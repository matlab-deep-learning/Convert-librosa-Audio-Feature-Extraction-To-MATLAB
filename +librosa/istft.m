function varargout = istft(Y,varargin)
% librosa.istft Inverse Short-time Fourier transform.
%
%  This function matches the istft function from Librosa (tested for
%  version 0.9.2). Parameter defaults are identical to the Librosa
%  function.
%
%  X = librosa.istft(Y) returns the inverse short-time Fourier transform
%  (istft) of Y.
%
%  X = librosa.istft(S, FFTLength=NFFT) specifies the FFT length used to
%  calculate the stft.
%
%  X = librosa.istft(S, Window=win) specifies the window used to compute
%  the stft. 
%
%  X = librosa.istft(S, HopLength=H) specifies the hop length.
%
%  X = librosa.istft(S, Center=center) specifies if the signal was
%  centered.
%
%  S = librosa.istft(X, GenerateMATLABCode=true) generates and opens an
%  untitled file containing code that implements the code of librosa.istft
%  using the MATLAB function istft.
%
% % EXAMPLE:
% % Compute the istft of a real signal using the overlap-add method.
% fs = 10240;
% t = 0:1/fs:0.5-1/fs;
% x = 5*sin(2*pi*t*10);
% win = hamming(512,'periodic');
% S = librosa.stft(x,'Window',win,'HopLength',numel(win)-384,...
%                  'FFTLength',1024);
% X = librosa.istft(S,'Window',win,'HopLength',numel(win)-384,...
%    'FFTLength',1024);
% 
% % Plot original and resynthesized signals.
% plot(1:numel(x),x,1:size(X,1),X,'-.')
% axis tight
% xlabel('Time bins')
% ylabel('Amplitude (V)')
% title('Original and Reconstructed Signal')
% legend('Original','Reconstructed')

%  Copyright 2022 The MathWorks, Inc.

%% Validate input signal
validateattributes(Y,{'single','double'},...
    {'nonempty','3d'}, ...
    'librosa.istft','Y')

%% Parse function parameters
p = inputParser;
addRequired(p,'Y');

validFFTLength = @(x) isnumeric(x) && isscalar(x) && (x > 0) && floor(x)==x;
addParameter(p,'FFTLength',2048,validFFTLength);

validHopLength = @(x) isnumeric(x) && isscalar(x) && (x > 0) && floor(x)==x;
addParameter(p,'HopLength',2048,validHopLength);

validWindowLength =  @(x) isnumeric(x) && isscalar(x) && (x > 0) && floor(x)==x;
addParameter(p,'WindowLength',2048,validWindowLength); 

validWindow = @(x) ischar(x) || isstring(x) || isvector(x) && isreal(x) &&isfloat(x);
addParameter(p,'Window',hann(2048,'periodic'),validWindow); 

validCenter = @(x)isscalar(x) && (isnumeric(x)||islogical(x));
addParameter(p,'Center',true,validCenter); 

validLength = @(x) isnumeric(x) && isscalar(x) && (x > 0) && floor(x)==x;
addParameter(p,'Length',true,validLength); 

validCodegen = @(x)isscalar(x) && (isnumeric(x)||islogical(x));
addParameter(p,'GenerateMATLABCode',false,validCodegen); 

parse(p,Y,varargin{:});

FFTLength = p.Results.FFTLength;
center = p.Results.Center;

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
        win = sprintf('%s(%d)',win,winlen);
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

lengthSpecified = ~ismember('Length',p.UsingDefaults);
len = p.Results.Length;

if numel(win)<FFTLength
    L = FFTLength-numel(win);
    L2 = floor(L/2);
    win = win(:);
    win = [zeros(L2,1); win; zeros(FFTLength-L2-numel(win),1)];
end

if p.Results.GenerateMATLABCode
    strWriter = StringWriter;
else
    strWriter = librosa.utils.StringWriter;
end

if lengthSpecified
    strWriter.addcr('%s\n%% Adjust length.','%%');
    if center
        padded_length = len + FFTLength;
        strWriter.addcr('padLength = %d+%d;',len,FFTLength);
    else
        padded_length = len;
        strWriter.addcr('padLength = %d;',len);
    end
    n_frames = min(size(Y,2),ceil(padded_length/hopLength));   
    Y = Y(:,1:n_frames,:);
    strWriter.addcr('numFrames = min(size(Y,2),ceil(padLength/%d));',hopLength);
    strWriter.addcr('Y = Y(:,1:numFrames,:)');
end

y = istft(Y,Window=win,...
          OverlapLength=numel(win)-hopLength,...
          FFTLength=FFTLength,...
          FrequencyRange="onesided");

strWriter.addcr('%s\n%% Compute ISTFT.','%%');
strWriter.addcr('y = istft(Y, Window=%s,...',mat2str(win(:),32));
strWriter.addcr('OverlapLength=%d,...',numel(win)-hopLength);
strWriter.addcr('FFTLength=%d,...',FFTLength);
strWriter.addcr('FrequencyRange="onesided");');

if ~lengthSpecified
    if center
        strWriter.addcr('%s\n%% STFT was centered.','%%');
        L = floor(FFTLength/2);
        y = y(L+1:size(y,1)-L,:);
        strWriter.addcr('L = floor(%d/2);',FFTLength);
        strWriter.addcr('y = y(L+1:size(y,1)-L,:);',FFTLength);
    end
else
    if center
        strWriter.addcr('%s\n%% STFT was centered.','%%');
        L = floor(FFTLength/2);
        strWriter.addcr('L = floor(%d/2);',FFTLength);
        y = y(L+1:L+len,:);
        strWriter.addcr('y = y(L+1:L+%d,:);',len);
    else
        y = y(1:len,:);
        strWriter.addcr('y = y(1:%d,:);',len);
    end
end

varargout{1} = y;
varargout{2} = strWriter.char;

generateMATLABCode = p.Results.GenerateMATLABCode;
if generateMATLABCode
    footer = sprintf('%% _Generated by MATLAB (R) and Audio Toolbox on %s_', string(datetime("now")));
    strWriter.addcr('\n%s\n%s','%%',footer);
    matlab.internal.liveeditor.openAsLiveCode(strWriter.char)
end
