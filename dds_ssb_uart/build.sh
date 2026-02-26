#!/usr/bin/env bash
set -e

# ======================================
# Polar SSB Docker Build Script
# For: davidsiaw/yosys-docker:latest
# ======================================

TOP="top"                 # Change if needed
DEVICE="25k"
PACKAGE="CABGA256"
SPEED="6"
FREQ="25"                 # 25 MHz external oscillator
LPF="dds.lpf"

IMAGE="davidsiaw/yosys-docker:latest"

JSON="${TOP}.json"
CFG="${TOP}.config"
BIT="${TOP}.bit"

echo "========================================"
echo " Polar SSB Docker Build"
echo "========================================"
echo "Top module: $TOP"
echo "Device:     ECP5-$DEVICE"
echo "Package:    $PACKAGE"
echo "Clock:      ${FREQ} MHz"
echo "Docker img: $IMAGE"
echo "========================================"

# Clean previous build artifacts
rm -f *.json *.config *.bit

# Run toolchain inside Docker
docker run --rm -it \
    -v "$PWD":/workspace \
    -w /workspace \
    $IMAGE \
    bash -c "
        set -e

        echo '--- Running Yosys ---'
        yosys -p \"
            read_verilog *.v;
            hierarchy -check -top $TOP;
            synth_ecp5 -top $TOP -json $JSON
        \"

        echo '--- Running nextpnr ---'
        nextpnr-ecp5 \
            --$DEVICE \
            --package $PACKAGE \
            --speed $SPEED \
            --json $JSON \
            --textcfg $CFG \
            --lpf $LPF \
            --freq $FREQ

        echo '--- Packing bitstream ---'
        ecppack $CFG $BIT

        echo '--- Done ---'
    "

echo "========================================"
echo "Build complete!"
echo "Generated: $BIT"
echo "========================================"
