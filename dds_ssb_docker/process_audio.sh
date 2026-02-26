#!/bin/bash
set -e

# 1. Extract 3 seconds of audio (from 3s to 6s), convert to 8kHz mono, and apply bandpass
ffmpeg -i Original_Kore.wav -ss 4 -t 10 -ar 8000 -ac 1 -af "highpass=f=300,lowpass=f=3000,loudnorm" temp_clean.wav -y -loglevel quiet

# 2. Use sox to ensure normalization
sox temp_clean.wav speech_8k.wav norm -1

echo "Audio pre-processed to speech_8k.wav (8kHz, Mono, Normalized)"
