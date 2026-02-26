
import numpy as np
import scipy.io.wavfile as wav

def play_mem(input_mem, output_wav, fs=4000):
    with open(input_mem, 'r') as f:
        hex_data = f.readlines()
    
    # Convert hex strings back to signed 16-bit integers
    vals = [np.int16(int(x.strip(), 16)) for x in hex_data]
    data = np.array(vals, dtype=np.int16)
    
    # Save as WAV
    wav.write(output_wav, fs, data)
    print(f"Converted {input_mem} to {output_wav}. Play it with your favorite player!")

if __name__ == "__main__":
    import sys
    mem_file = sys.argv[1] if len(sys.argv) > 1 else 'audio_4k.mem'
    play_mem(mem_file, 'verify_mem.wav')
