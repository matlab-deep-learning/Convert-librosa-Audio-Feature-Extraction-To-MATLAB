import librosa

import warnings
warnings.filterwarnings("ignore")

# Read audio
desired_sr = 16e3
samples, sr = librosa.load(filename,sr=desired_sr)

# Mel spectrogram
melSpectrogramOut = librosa.feature.melspectrogram(y=samples,
                                                   sr=sr,
                                                   n_fft=512,
                                                   n_mels=50, 
                                                   norm="slaney",
                                                   htk=False,
                                                   hop_length=160,
                                                   win_length=512,
                                                   window="hann",
                                                   center=False,
                                                   power=2)
