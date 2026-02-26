import serial
import time
import numpy as np
import subprocess
import sys
import argparse
from scipy.signal import hilbert

def stream_audio(port, input_file, bypass=False, intelligible=False):
    TARGET_FS = 48000
    BAUD = 6000000
    FPGA_CLK = 100000000

    if bypass:
        print("Mode: Bypass (Raw Audio)")
        filter_chain = 'anull'
    elif intelligible:
        print("Mode: High-Intelligibility (Digital Reconstruction Style)")
        # Fixed speechnorm parameters: m must be between 0 and 1
        filter_chain = (
            'afftdn=nf=-30,'
            'highpass=f=400,lowpass=f=2200,'
            'equalizer=f=1500:width_type=h:width=1000:g=8,'
            'speechnorm=e=20:p=0.9:m=0.5,'
            'acompressor=threshold=-10dB:ratio=20:attack=1:release=30,'
            'volume=1.2,alimiter=limit=0.9'
        )
    else:
        print("Mode: Communications (Standard SSB)")
        filter_chain = (
            'speechnorm=e=4:p=0.75:m=0.1,'
            'highpass=f=300,lowpass=f=2400,'
            'alimiter=level_in=1:level_out=0.8:limit=0.9:attack=5:release=50'
        )

    command = [
        'ffmpeg', '-i', input_file,
        '-f', 'f32le', '-ac', '1', '-ar', str(TARGET_FS),
        '-af', filter_chain, '-v', 'quiet', '-'
    ]

    ffmpeg_proc = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    raw_bytes, stderr = ffmpeg_proc.communicate()
    if ffmpeg_proc.returncode != 0:
        print(f"Error: ffmpeg failed.")
        print(stderr.decode())
        sys.exit(1)

    data = np.frombuffer(raw_bytes, dtype=np.float32)

    # Always normalize to peak
    max_val = np.max(np.abs(data))
    if max_val > 0:
        print(f"Normalizing signal (Peak: {max_val:.4f})...")
        data = data * (0.9 / max_val)
    else:
        print("Warning: File is silent.")
        return

    print("Processing Robust Phase Extraction...")
    analytic = hilbert(data)
    z = analytic
    freq_dev = np.zeros(len(z))
    freq_dev[1:] = np.angle(z[1:] * np.conj(z[:-1]))

    # Gate
    amplitude = np.abs(z)
    gate_mask = amplitude < 0.01
    freq_dev[gate_mask] = 0

    # Scaling
    audio_inc = (freq_dev / (2 * np.pi) * (2**32)) / 2083.33

    # Strict Bandwidth Limit
    max_shift_hz = 3000
    limit = int((max_shift_hz / FPGA_CLK) * (2**32))
    audio_inc = np.clip(audio_inc, -limit, limit)
    audio_inc = audio_inc.astype(np.int32)

    with serial.Serial(port, BAUD, timeout=1) as ser:
        print(f"Streaming to {port}...")
        time.sleep(0.1)
        start_time = time.time()
        samples_sent = 0
        CHUNK = 512
        for i in range(0, len(audio_inc), CHUNK):
            batch = audio_inc[i:i+CHUNK]
            packet = bytearray()
            for val in batch:
                uval = np.uint32(val)
                packet.extend([(uval >> 0) & 0xFF, (uval >> 8) & 0xFF, (uval >> 16) & 0xFF, (uval >> 24) & 0xFF])
            ser.write(packet)
            samples_sent += len(batch)
            expected_time = samples_sent / float(TARGET_FS)
            actual_time = time.time() - start_time
            if (expected_time - actual_time) > 0.01:
                time.sleep(expected_time - actual_time - 0.01)
        print(f"Finished.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Stream audio to FPGA SSB DDS via UART')
    parser.add_argument('port', help='Serial port')
    parser.add_argument('file', help='Audio file')
    parser.add_argument('--bypass', action='store_true', help='Bypass all filters')
    parser.add_argument('--intelligible', action='store_true', help='High-intelligibility mode')
    args = parser.parse_args()

    try:
        stream_audio(args.port, args.file, args.bypass, args.intelligible)
    except KeyboardInterrupt:
        print("\nStopped.")
    except Exception as e:
        print(f"\nError: {e}")
