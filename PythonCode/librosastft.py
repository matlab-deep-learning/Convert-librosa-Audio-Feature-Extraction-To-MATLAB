import librosa

import warnings
warnings.filterwarnings("ignore")

# Read audio
desired_sr = 16e3
samples, sr = librosa.load(filename,sr=desired_sr)

# STFT
stftOut = librosa.stft(samples,
                       n_fft=512,
                       hop_length=160,
                       win_length=512,
                       window="hann",
                       center=True)

# ISTFT
istftOut = librosa.istft(stftOut,
                         n_fft=512,
                         hop_length=160,
                         win_length=512,
                         window="hann",
                         center=True)
