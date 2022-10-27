import librosa

import warnings
warnings.filterwarnings("ignore")

# Read audio
sr = 16e3
samples, sr = librosa.load(filename, sr)

# MFCC
mfccOut = librosa.feature.mfcc(samples,sr=sr,n_fft=512, n_mels=50,
                               hop_length=160,win_length=512,
                               window="hann", htk=True,power=2,
                               dct_type=2,lifter=.2)