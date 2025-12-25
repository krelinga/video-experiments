#!/usr/bin/env bash

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <video_file>"
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "Error: File '$1' not found"
    exit 1
fi

resolution=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$1")

echo "$resolution"
