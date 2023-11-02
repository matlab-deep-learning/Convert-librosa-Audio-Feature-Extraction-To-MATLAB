import librosa

import warnings
warnings.filterwarnings("ignore")

# Read audio
desired_sr = 16e3
samples, sr = librosa.load(filename,sr=desired_sr)

# MFCC
mfccOut = librosa.feature.mfcc(y=samples,
                               sr=sr,
                               n_fft=512,
                               n_mels=50,
                               hop_length=160,
                               win_length=512,
                               window="hann",
                               htk=False,
                               power=2,
                               dct_type=2,
                               lifter=.2)
