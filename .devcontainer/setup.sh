#! /usr/bin/bash

set -e

echo "updating apt cache..."
sudo apt-get update
echo "done."

echo "Installing ffmpeg..."
sudo apt-get install -y ffmpeg
echo "done."

echo "Installing handbrake-cli..."
sudo apt-get install -y handbrake-cli
echo "done."

echo "Cleaning up apt cache..."
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
echo "done."