import numpy as np
import scipy.io.wavfile as wav
from scipy.signal import hilbert
import os

def generate_ssb_mem(input_wav, output_mem):
    fs, data = wav.read(input_wav)
    data = data.astype(float) / 32768.0

    # Hilbert transform
    analytic = hilbert(data)

    # Instantaneous Frequency Deviation
    freq_dev = np.diff(np.unwrap(np.angle(analytic)), prepend=0)

    # Scaling for 25MHz FPGA clock
    # audio_inc = (freq_dev / 2pi) * 2^32 / (Fclk/Fs)
    # Cycles per sample = 25,000,000 / 8,000 = 3125
    audio_inc = (freq_dev / (2 * np.pi) * (2**32)) / 3125
    audio_inc = audio_inc.astype(np.int32)

    # Write 24,000 samples (3 seconds at 8kHz)
    with open(output_mem, 'w') as f:
        for val in audio_inc[:128000]:
            f.write(f"{np.uint32(val):08x}\n")

    print(f"Generated {output_mem} with {len(audio_inc[:48000])} samples.")

if __name__ == "__main__":
    generate_ssb_mem('speech_8k.wav', 'audio_8k.mem')
