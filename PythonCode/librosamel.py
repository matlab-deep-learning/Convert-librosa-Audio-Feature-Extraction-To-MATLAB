import librosa

import warnings
warnings.filterwarnings("ignore")

sr = 16e3

# Mel Filter bank
melOut = librosa.filters.mel(sr=sr,n_fft=512, n_mels=50,
                             norm="slaney", htk=True)