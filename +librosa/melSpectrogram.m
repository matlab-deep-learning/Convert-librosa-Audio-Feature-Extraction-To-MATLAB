function varargout = melSpectrogram(y,varargin)
% librosa.melSpectrogram Compute mel spectrogram
%
%  This function matches the melSpectrogram function from Librosa (tested
%  for version 0.9.2). Parameter defaults are identical to the Librosa
%  function.
%
%  S = librosa.melSpectrogram(audioIn) returns the mel spectrogram of
%  audioIn.
%
%  S = librosa.melSpectrogram(audioIn, FFTLength=NFFT) specifies the FFT
%  length.
%
%  S = librosa.melSpectrogram(audioIn, Window=win) specifies the window
%  used to compute the stft.
%
%  S = librosa.melSpectrogram(audioIn, HopLength=H) specifies the hop
%  length.
%
%  S = librosa.melSpectrogram(audioIn, Center=center) specifies if the
%  signal is centered. If center is true, audioIn is padded as documented
%  by the stft function in the Librosa package.
%
%  S = librosa.melSpectrogram(audioIn, PaddingMode=mode) defines the
%  padding mode of the signal. Padding applies when Center is true.
%
%  S = librosa.melSpectrogram(audioIn, NumBands=NUMBANDS) specifies the
%  number of bands in the filter bank.
%
%  S = librosa.melSpectrogram(audioIn, Fmin=FMIN) specifies the lowest
%  filter bank frequency (in Hz).
% 
%  S = librosa.melSpectrogram(audioIn, Fmax=FMAX) specifies the highest
%  filter bank frequency (in Hz).
% 
%  S = librosa.melSpectrogram(audioIn, Normalization=NORM) specifies the
%  type of filter bank normalization.
%
%  S = librosa.melSpectrogram(audioIn, Power=P) specifies the exponent for
%  the magnitude melspectrogram.
%
%  S = librosa.melSpectrogram(audioIn, HTK=FLAG) specifies what type of
%  Mel scaling is used. If FLAG is true, HTK scaling is used. If FLAG is
%  false, Slaney scaling is used. This function only supports HTK scaling,
%  which is the non-default of the Librosa function. Set HTK=true in the
%  function call.
%
%  S = librosa.melSpectrogram(audioIn, Spectrum=S) specifies the
%  pre-computed spectrogram. If Spectrum is specified, audioIn is ignored,
%  and the spectrogram computation is bypassed.
%
%  S = librosa.melSpectrogram(audioIn, GenerateMATLABCode=true) generates
%  and opens an untitled file containing code that implements the code of
%  librosa.melSpectrogram using the MATLAB functions stft and
%  designAuditoryFilterBank.
%
%  % Example:
%  % Compute the mel spectrogram from a speech file.
%  [audioIn,fs] = audioread("Counting-16-44p1-mono-15secs.wav");
%  S = librosa.melSpectrogram(audioIn,SampleRate=fs, HTK=true);

%  Copyright 2022 The MathWorks, Inc.

%% Parse function parameters
p = inputParser;
addRequired(p,'y');

% STFT arguments
addParameter(p,'FFTLength',2048);
addParameter(p,'HopLength',512);
addParameter(p,'Window',hann(2048,'periodic')); 
addParameter(p,'Center',true); 
addParameter(p,'PadMode',"Constant"); 
addParameter(p,'WindowLength',2048); 

% Mel filter bank arguments
addParameter(p,'SampleRate',22050); 
addParameter(p,'NumBands',128); 
addParameter(p,'Fmin',0); 
addParameter(p,'Fmax',8000);
addParameter(p,'HTK',false); 
addParameter(p,'Normalization','Slaney'); 

% Mel spectrogram arguments
validPower = @(x) isnumeric(x) && isscalar(x) && (x>0);
addParameter(p,'Power',2,validPower); 
addParameter(p,'Spectrum',[]); 
validCodegen = @(x)isscalar(x) && (isnumeric(x)||islogical(x));
addParameter(p,'GenerateMATLABCode',false,validCodegen); 

parse(p,y,varargin{:});

if p.Results.GenerateMATLABCode
    strWriter = StringWriter;
else
    strWriter = librosa.utils.StringWriter;
end

if ismember('Spectrum',p.UsingDefaults)
    % Using time-series
    validateattributes(y,{'single','double'},...
        {'nonempty','2d'}, ...
        'librosa.melSpectrogram','y');
    stftArgs = {'FFTLength','HopLength','Window','WindowLength','Center','PadMode','GenerateMATLABCode'};
    subInd = [];
    for index=1:2:length(varargin)
        if ismember(char(varargin{index}),stftArgs)
            subInd = [subInd index index+1];%#ok
        end
    end
    [Y,stftCode] = librosa.stft(y,varargin{subInd},HopLength=p.Results.HopLength);
    
    strWriter.addcr('%s',stftCode);

    Y = abs(Y).^(p.Results.Power);
    strWriter.addcr('%s\n%% Convert to power spectrum.','%%');
    strWriter.addcr('Y = abs(Y).^%f;',p.Results.Power);

    numChans = size(y,2);
else
    Y = p.Results.Spectrum;
    numChans = size(Y,3);
    if numChans>1
        strWriter.addcr('numChannels = %d;',size(Y,3));
    end
end

FBArgs = {'FFTLength','SampleRate','NumBands','Fmin','Fmax','HTK','Norm','GenerateMATLABCode'};
subInd = [];
for index=1:2:length(varargin)
     if ismember(char(varargin{index}),FBArgs)
         subInd = [subInd index index+1];%#ok
     end
end
if ismember('Spectrum',p.UsingDefaults)
    [filterBank,fbCode] = librosa.mel(varargin{subInd});
else
    [filterBank,fbCode] = librosa.mel(varargin{subInd},'FFTLength',2*(size(Y,1)-1));
end

strWriter.addcr('%s',fbCode);

Y = reshape(Y,size(Y,1),[]);
Z = filterBank*Y;
Z = reshape(Z,size(Z,1), size(Z,2) / numChans , numChans);

strWriter.addcr('%s\n%% Compute Mel spectrogram.','%%');

if numChans>1
    strWriter.addcr('Y = reshape(Y,size(Y,1),[]);');
end

strWriter.addcr('Z = filterBank*Y;');

if numChans>1
    strWriter.addcr('Z = reshape(Z,size(Z,1), size(Z,2) / numChannels , numChannels);');
end

varargout{1} = Z;
varargout{2} = strWriter.char;

if p.Results.GenerateMATLABCode
    footer = sprintf('%% _Generated by MATLAB (R) and Audio Toolbox on %s_', string(datetime("now")));
    strWriter.addcr('\n%s\n%s','%%',footer);
    matlab.internal.liveeditor.openAsLiveCode(strWriter.char)
end
end