#!/usr/bin/env bash

# Results:
# ./slideshow.sh /nas/media/Movies/The\ Void\ \(2016\)/The\ Void\ \(2016\).mkv 428x240
# Processor cores: 23
# Input size:      19GiB
# Output size:     67MiB
# Reduction:       99.64%
# Elapsed time:    168.98s

# ./slideshow.sh /nas/media/Movies/Mad\ Max\ Fury\ Road\ \(2015\)/Mad\ Max\ Fury\ Road\ \(2015\).mkv 428x240
# Processor cores: 23
# Input size:      28GiB
# Output size:     156MiB
# Reduction:       99.44%
# Elapsed time:    310.20s

# Things I tried that did not result in any speed-up:
# -threads "$NUM_CORES"
# -b:a 8k - this actually slowed this down substantially, Fury Road took 353 seconds instead of 310s.  It did shrink the output size to 140MiB.
# - copying the input file to local ssd (/tmp) first - no noticeable speed-up
# -preset ultrafast ... no noticeable speed-up
# -tune fastdecode ... no noticeable speed-up
# -x264-params "bframes=0:ref=1" ... no noticeable speed-up

# Things to make the file size smaller:
# using fps=1 reduced the file size for fury road to 133Mib and decreased time to 271s.
# using fps=0.5 reduced the file size for fury road to 84MiB and decreased time to 264s.  The down-side is that the video got a lot less-watchable vs. 1 fps.

# I think 1 fps is probably the sweet spot, let's leave it there.
# Just to confirm, I tested this with The Void and got 62MiB output size at 171 seconds, so that also checks out.

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

# Get the base filename without path
BASENAME=$(basename "$VIDEO_FILE")
FILENAME="${BASENAME%.*}"
OUTPUT_FILE="/nas/dev/${FILENAME}.mp4"

# Check if output file already exists
if [ -f "$OUTPUT_FILE" ]; then
    echo "Error: Output file '$OUTPUT_FILE' already exists"
    exit 1
fi

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
    -vf "fps=1,scale=${RESOLUTION}" \
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
echo "$OUTPUT_FILE"
