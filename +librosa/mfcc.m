function varargout = mfcc(y,varargin)
% librosa.mfcc Compute mel-frequency cepstral coefficients
%
%  This function matches the mfcc function from Librosa (tested for
%  version 0.10.1). Parameter defaults are identical to the Librosa
%  function.
%
%  Coeffs = librosa.mfcc(audioIn) returns the mel-frequency cepstral
%  coefficients of audioIn.
%
%  Coeffs = librosa.mfcc(audioIn, FFTLength=NFFT) specifies the FFT length.
%
%  Coeffs = librosa.mfcc(audioIn, Window=win) specifies the window used to
%  compute the stft.
%
%  Coeffs = librosa.mfcc(audioIn, HopLength=H) specifies the hop length.
%
%  Coeffs = librosa.mfcc(audioIn, Center=center) specifies if the signal is
%  centered. If center is true, audioIn is padded as documented by the stft
%  function in the Librosa package.
%
%  Coeffs = librosa.mfcc(audioIn, PaddingMode=mode) defines the padding
%  mode of the signal. Padding applies when Center is true.
%
%  Coeffs = librosa.mfcc(audioIn, NumBands=NUMBANDS) specifies the number
%  of bands in the filter bank.
%
%  Coeffs = librosa.mfcc(audioIn, Fmin=FMIN) specifies the lowest filter
%  bank frequency (in Hz).
% 
%  Coeffs = librosa.mfcc(audioIn, Fmax=FMAX) specifies the highest filter
%  bank frequency (in Hz).
% 
%  Coeffs = librosa.mfcc(audioIn, Normalization=NORM) specifies the type of
%  filter bank normalization.
%
%  Coeffs = librosa.mfcc(audioIn, Power=P) specifies the exponent for the
%  magnitude melspectrogram.
%
%  Coeffs = librosa.mfcc(audioIn, HTK=FLAG) specifies what type of Mel
%  scaling is used. If FLAG is true, HTK scaling is used. If FLAG is false,
%  Slaney scaling is used.
%
%  Coeffs = librosa.mfcc(audioIn, Spectrum=S) specifies the pre-computed
%  spectrogram. If Spectrum is specified, audioIn is ignored, and the
%  spectrogram computation is bypassed.
%
%  Coeffs = librosa.mfcc(audioIn, NumCoeffs=S) specifies the number of mfcc
%  coefficients computed per window.
%
%  Coeffs = librosa.mfcc(audioIn, DCTType=type) specifies the DCT type.
%
%  Coeffs = librosa.mfcc(audioIn, Lifter=LIFT) specifies the spectral
%  lifetering value. Set LIFT to a non-zero value to apply liftering.
%
%  Coeffs = librosa.mfcc(audioIn, GenerateMATLABCode=true) generates and
%  opens an untitled file containing code that implements the code of
%  librosa.mfcc using the MATLAB functions stft, designAuditoryFilterBank
%  and dct.
%
%  % Example: 
%  % Compute mfcc from a speech file. [audioIn,fs] =
%  audioread("Counting-16-44p1-mono-15secs.wav"); 
%  Coeffs = librosa.mfcc(audioIn,SampleRate=fs, HTK=true);

%  Copyright 2022-2023 The MathWorks, Inc.

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
addParameter(p,'Power',2); 
addParameter(p,'Spectrum',[]); 
addParameter(p,'GenerateMATLABCode',false); 

% MFCC arguments
validNumCoeffs = @(x) isnumeric(x) && isscalar(x) && (x > 0) && floor(x)==x;
addParameter(p,'NumCoeffs',20, validNumCoeffs); 
addParameter(p,'DCTType',2, @(x) x==1 || x==2 || x==3); 
validLifter = @(x) isnumeric(x) && isscalar(x) && (x>=0);
addParameter(p,'Lifter',0, validLifter); 

parse(p,y,varargin{:});

melArgs = {'FFTLength','HopLength','Window', 'WindowLength','Center','PadMode','Power','SampleRate','NumBands','Fmin','Fmax','HTK','Norm','Spectrum','GenerateMATLABCode'};
subInd = [];
for index=1:2:length(varargin)
     if ismember(char(varargin{index}),melArgs)
         subInd = [subInd index index+1];%#ok
     end
end

if p.Results.GenerateMATLABCode
    strWriter = StringWriter;
else
    strWriter = librosa.utils.StringWriter;
end

% Power to dB
if ismember('Spectrum',p.UsingDefaults)
    [Z,melCode] = librosa.melSpectrogram(y,varargin{subInd},HopLength=p.Results.HopLength);
    strWriter.addcr('%s',melCode);
    strWriter.addcr('%s\n%% Convert to log spectrum.','%%');
    amin = cast(1e-10,class(Z));
    ZdB = 10.0 * log10(max(amin, Z));
    ZdB = max(ZdB, max(ZdB(:)) - 80);
    strWriter.addcr('amin = cast(1e-10,class(Z));');
    strWriter.addcr('ZdB = 10.0 * log10(max(amin,Z));');
    strWriter.addcr('ZdB = max(ZdB, max(ZdB(:))-80);');
else
    ZdB = p.Results.Spectrum;
end

% DCT
strWriter.addcr('%s\n%% Compute DCT.','%%');
coeffs = dct(ZdB,[],1,"Type",p.Results.DCTType);
coeffs = coeffs(1:p.Results.NumCoeffs,:,:);
strWriter.addcr('coeffs = dct(ZdB,[],1,"Type",%d);',p.Results.DCTType);
strWriter.addcr('coeffs = coeffs(1:%d,:,:);',p.Results.NumCoeffs);

lifter = p.Results.Lifter;
if lifter ~=0
    strWriter.addcr('%s\n%% Apply liftering.','%%');
    LI =  sin(pi * (1:p.Results.NumCoeffs) / lifter).';
    coeffs = coeffs .* (1 + (lifter / 2) * LI);
    strWriter.addcr('LI =  sin(pi * (1:%d) / %f).'';',p.Results.NumCoeffs,lifter);
    strWriter.addcr('coeffs = coeffs .* (1 + (%f / 2) * LI);',lifter);
end

varargout{1} = coeffs;
varargout{2} = strWriter.char;

if p.Results.GenerateMATLABCode
    footer = sprintf('%% _Generated by MATLAB (R) and Audio Toolbox on %s_', string(datetime("now")));
    strWriter.addcr('\n%s\n%s','%%',footer);
    matlab.internal.liveeditor.openAsLiveCode(strWriter.char)
end

end
