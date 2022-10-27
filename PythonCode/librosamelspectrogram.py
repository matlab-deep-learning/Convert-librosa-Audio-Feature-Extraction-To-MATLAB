import librosa

import warnings
warnings.filterwarnings("ignore")

# Read audio
sr = 16e3
samples, sr = librosa.load(filename, sr)

# Mel spectrogram
melSpectrogramOut = librosa.feature.melspectrogram(samples,sr=sr,
                    n_fft=512,n_mels=50, norm="slaney",htk=True,hop_length=160,
                    win_length=512,window="hann",center=False,power=2)