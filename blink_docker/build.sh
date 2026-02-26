#!/bin/bash
# Build script for Colorlight 5A-75B blink example using Docker

DOCKER_IMAGE="davidsiaw/yosys-docker:latest"
PROJECT_DIR="$(pwd)"

echo "Building Colorlight 5A-75B blink example using $DOCKER_IMAGE..."

docker run --rm \
    -v "$PROJECT_DIR":/src \
    -w /src \
    "$DOCKER_IMAGE"\
    make clean all

echo "Build complete. Bitstream and SVF files are in $PROJECT_DIR"
