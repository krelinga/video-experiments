#!/usr/bin/env bash

# Results:
# ./slideshow.sh /nas/media/Movies/The\ Void\ \(2016\)/The\ Void\ \(2016\).mkv 428x240
# Processor cores: 23
# Input size:      19GiB
# Output size:     67MiB
# Reduction:       99.64%
# Elapsed time:    168.98s

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <video_file> <resolution>"
    echo "Example: $0 video.mp4 1920x1080"
    exit 1
fi

VIDEO_FILE="$1"
RESOLUTION="$2"

if [ ! -f "$VIDEO_FILE" ]; then
    echo "Error: File '$VIDEO_FILE' not found"
    exit 1
fi

# Validate resolution format
if ! [[ "$RESOLUTION" =~ ^[0-9]+x[0-9]+$ ]]; then
    echo "Error: Resolution must be in format WIDTHxHEIGHT (e.g., 1920x1080)"
    exit 1
fi

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Get the base filename without path
BASENAME=$(basename "$VIDEO_FILE")
FILENAME="${BASENAME%.*}"
OUTPUT_FILE="$TEMP_DIR/${FILENAME}_keyframes.mp4"

# Get input file size
INPUT_SIZE=$(stat -c%s "$VIDEO_FILE")

# Get number of processor cores
NUM_CORES=$(nproc)

# Transcode with ffmpeg
# -skip_frame nokey: skip all frames except key frames
# -vf scale: resize to target resolution
# -c:v libx264: use h264 codec
# -ac 1: mono audio (1 channel)
# -c:a aac: use AAC audio codec
# -b:a 32k: 32kbps audio bitrate
START_TIME=$(date +%s.%N)
ffmpeg -skip_frame nokey -i "$VIDEO_FILE" \
    -vf "scale=${RESOLUTION}" \
    -c:v libx264 \
    -ac 1 \
    -c:a aac \
    -b:a 32k \
    "$OUTPUT_FILE" \
    -y
END_TIME=$(date +%s.%N)

# Calculate elapsed time
ELAPSED=$(awk "BEGIN {printf \"%.2f\", $END_TIME - $START_TIME}")

# Get output file size
OUTPUT_SIZE=$(stat -c%s "$OUTPUT_FILE")

# Calculate human-readable sizes
INPUT_SIZE_HUMAN=$(numfmt --to=iec-i --suffix=B "$INPUT_SIZE")
OUTPUT_SIZE_HUMAN=$(numfmt --to=iec-i --suffix=B "$OUTPUT_SIZE")

# Calculate reduction percentage
REDUCTION=$(awk "BEGIN {printf \"%.2f\", (1 - $OUTPUT_SIZE / $INPUT_SIZE) * 100}")

echo "Processor cores: $NUM_CORES"
echo "Input size:      $INPUT_SIZE_HUMAN"
echo "Output size:     $OUTPUT_SIZE_HUMAN"
echo "Reduction:       ${REDUCTION}%"
echo "Elapsed time:    ${ELAPSED}s"
echo ""
echo "$TEMP_DIR"
