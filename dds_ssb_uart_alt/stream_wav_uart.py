import serial
import time
import numpy as np
import subprocess
import sys
import argparse
from scipy.signal import hilbert

def stream_audio(port, input_file, use_ack=True):
    TARGET_FS = 48000
    BAUD = 2000000

    filter_chain = 'speechnorm=e=2:p=0.75:m=0.1,highpass=f=200,lowpass=f=3500,alimiter=level_out=0.9'

    command = ['ffmpeg', '-i', input_file, '-f', 'f32le', '-ac', '1', '-ar', str(TARGET_FS), '-af', filter_chain, '-v', 'quiet', '-']
    ffmpeg_proc = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    raw_bytes, stderr = ffmpeg_proc.communicate()
    data = np.frombuffer(raw_bytes, dtype=np.float32)

    print("Processing Hilbert Transform...")
    z = hilbert(data)
    freq_dev = np.zeros(len(z))
    freq_dev[1:] = np.angle(z[1:] * np.conj(z[:-1]))
    freq_int = ((freq_dev / (2 * np.pi)) * ((2**32) / 2083.3333)).astype(np.int32)

    print(f"Streaming {len(freq_int)} samples to {port} @ 2 Mbps...")
    with serial.Serial(port, BAUD, timeout=0.05) as ser:
        ser.reset_input_buffer()
        samples_sent = 0
        acks_received = 0
        CHUNK = 64

        for i in range(0, len(freq_int), CHUNK):
            batch = freq_int[i:i+CHUNK]
            packet = bytearray()
            for f in batch:
                u_f = np.uint32(f)
                packet.extend([u_f & 0xFF, (u_f >> 8) & 0xFF, (u_f >> 16) & 0xFF, (u_f >> 24) & 0xFF])

            ser.write(packet)
            samples_sent += len(batch)

            if use_ack:
                try:
                    if ser.in_waiting > 0:
                        acks_received += ser.read(ser.in_waiting).count(0x06)

                    while samples_sent - acks_received > 800:
                        ack_byte = ser.read(1)
                        if ack_byte:
                            acks_received += ack_byte.count(0x06)
                        else:
                            break # Safety break
                except Exception:
                    pass # Ignore USB-Serial driver jitters
            else:
                time.sleep(CHUNK / float(TARGET_FS) * 0.9)

            if i % (CHUNK * 32) == 0:
                print(f"\rProgress: {i/len(freq_int)*100:.1f}% | ACKs: {acks_received} | Buffer: {samples_sent - acks_received}", end="")

        print(f"\nWaiting for FIFO to drain...")
        timeout_start = time.time()
        while acks_received < (samples_sent - 10) and (time.time() - timeout_start) < 2.5:
            try:
                if ser.in_waiting > 0:
                    acks_received += ser.read(ser.in_waiting).count(0x06)
            except Exception:
                pass
            time.sleep(0.01)

        print(f"Finished. Sent {samples_sent}, Received {acks_received} ACKs.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('port')
    parser.add_argument('file')
    parser.add_argument('--no-ack', action='store_true')
    args = parser.parse_args()
    try:
        stream_audio(args.port, args.file, not args.no_ack)
    except KeyboardInterrupt:
        print("\nStopped.")
