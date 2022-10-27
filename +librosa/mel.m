function varargout = mel(varargin)
% librosa.stft Design Mel filter bank
%
%  This function matches the mel function from Librosa (tested for
%  version 0.9.2). Parameter defaults are identical to the Librosa
%  function.
%
%  FB = librosa.mel(SampleRate=fs) returns a frequency-domain
%  Mel filter bank, filterBank. fs is the input sample rate, in Hz.
%
%  FB = librosa.mel(FFTLength=NFFT) specifies the FFT length.
%
%  FB = librosa.mel(NumBands=NUMBANDS) specifies the number of bands in
%  the filter bank.
%
%  FB = librosa.mel(Fmin=FMIN) specifies the lowest frequency (in Hz).
% 
%  FB = librosa.mel(Fmax=FMAX) specifies the highest frequency (in Hz).
% 
%  FB = librosa.mel(Normalization=NORM) specifies the type of filter bank
%  normalization.
%
%  FB = librosa.mel(HTK=FLAG) specifies what type of Mel scaling is used.
%  If FLAG is true, HTK scaling is used. If FLAG is false, Slaney scaling
%  is used. This function only supports HTK scaling, which is the
%  non-default of the Librosa function. Set HTK=true in the function call.
%
%  FB = librosa.mel(GenerateMATLABCode=true) generates and opens an
%  untitled file containing code that implements the code of librosa.mel
%  using the MATLAB function designAuditoryFilterBank.
%
%  % Example:
%  % Design an auditory filter bank and use it to compute a mel
%  % spectrogram.
%
%  [audioIn,fs] = audioread("Counting-16-44p1-mono-15secs.wav");
%       
%  % Compute spectrogram
%  win = hann(1024,"periodic");
%  [~,F,T,S] = spectrogram(audioIn,win,512,1024,fs,"onesided");
%
%  % Design auditory filter bank
%  filterBank = librosa.mel(SampleRate=fs,FFTLength=1024, ...
%                     NumBands=16,Normalization="None", HTK=true);
%
%  % Visualize filter bank
%  plot(F,filterBank.')
%  grid on
%  title("Mel Filter Bank")
%  xlabel("Frequency (Hz)")
%      
%  % Compute mel spectrogram
%  SMel = filterBank*S;

%  Copyright 2022 The MathWorks, Inc.

%% Parse function parameters
p = inputParser;

validFFTLength = @(x) isnumeric(x) && isscalar(x) && (x > 0) && floor(x)==x;
addParameter(p,'FFTLength',2048,validFFTLength);
validSampleRate = @(x) isnumeric(x) && isscalar(x) && (x>0);
addParameter(p,'SampleRate',22050,validSampleRate); 
validNumBands = @(x) isnumeric(x) && isscalar(x) && (x > 0) && floor(x)==x;
addParameter(p,'NumBands',128,validNumBands); 
validFmin = @(x) isnumeric(x) && isscalar(x) && (x>0);
addParameter(p,'Fmin',0,validFmin); 
validFmax = @(x) isnumeric(x) && isscalar(x) && (x>0);
addParameter(p,'Fmax',8000,validFmax);
validHTK = @(x)isscalar(x) && (isnumeric(x)||islogical(x));
addParameter(p,'HTK',false,validHTK); 
validNorm = @(x) (isnumeric(x) && isscalar(x)) || (ismember(char(x),{'Slaney','None'}));
addParameter(p,'Normalization','Slaney',validNorm); 
validCodegen = @(x)isscalar(x) && (isnumeric(x)||islogical(x));
addParameter(p,'GenerateMATLABCode',false,validCodegen); 

parse(p,varargin{:});

if ismember('Fmax',p.UsingDefaults)
    fmax = p.Results.SampleRate/2;
else
    fmax = min(p.Results.SampleRate/2,p.Results.Fmax);
end

if ~p.Results.HTK
    error('Slaney scaling is not supported. Set HTK to true.');
end

norm = p.Results.Normalization;
customNorm = false;
switch norm
    case 'None'
        norm = 'none';
    case 'Slaney'
        norm = 'bandwidth';
    otherwise
        norm = 'none';
        customNorm = true;
end

if p.Results.GenerateMATLABCode
    strWriter = StringWriter;
else
    strWriter = librosa.utils.StringWriter;
end
strWriter.addcr('%s\n%% Construct filter bank.','%%');

filterBank = designAuditoryFilterBank(p.Results.SampleRate,...
                                      "FrequencyScale","mel",...
                                      "FFTLength",p.Results.FFTLength,...
                                      "NumBands",p.Results.NumBands,...
                                      "FrequencyRange",[p.Results.Fmin fmax],...
                                      "Normalization",norm,...
                                      "OneSided",true,...
                                      "FilterBankDesignDomain","linear");

strWriter.addcr('filterBank = designAuditoryFilterBank(%f,...',p.Results.SampleRate);
strWriter.addcr('FrequencyScale="mel",...');
strWriter.addcr('FFTLength=%d,...',p.Results.FFTLength);
strWriter.addcr('NumBands=%d,...',p.Results.NumBands);
strWriter.addcr('FrequencyRange=[%f %f],...',p.Results.Fmin,fmax);
strWriter.addcr('Normalization=''%s'',...',norm);
strWriter.addcr('OneSided=true,...');
strWriter.addcr('FilterBankDesignDomain="linear");');

if customNorm
    n = p.Results.Normalization;
    strWriter.addcr('%s\n%% Normalize filter bank.','%%');
    if ~isequal(n,-Inf)
        val = vecnorm(filterBank,n,2);
        strWriter.addcr('n = vecnorm(filterBank,%f,2);',p.Results.Normalization);
        filterBank = filterBank./val;
        strWriter.addcr('filterBank = filterBank./n;');
    end
end

varargout{1} = filterBank;
varargout{2} = strWriter.char;

if p.Results.GenerateMATLABCode
    footer = sprintf('%% _Generated by MATLAB (R) and Audio Toolbox on %s_', string(datetime("now")));
    strWriter.addcr('\n%s\n%s','%%',footer);
    matlab.internal.liveeditor.openAsLiveCode(strWriter.char)
end
end